import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:frontend/state/auth_provider.dart';
import 'package:frontend/screens/home/home_screen.dart';

List<CameraDescription> _cameras = [];

class LoginFaceScreen extends StatefulWidget {
  const LoginFaceScreen({super.key});

  @override
  State<LoginFaceScreen> createState() => _LoginFaceScreenState();
}

class _LoginFaceScreenState extends State<LoginFaceScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isCameraReady = false;
  String _feedbackMessage = "Requesting camera permission...";

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initCamera();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (status != PermissionStatus.granted) {
      setState(() {
        _feedbackMessage =
            "Camera permission denied. Please enable it in settings.";
      });
      return;
    }

    try {
      if (_cameras.isEmpty) {
        _cameras = await availableCameras();
      }

      if (_cameras.isEmpty) {
        setState(() => _feedbackMessage = "No camera detected.");
        return;
      }

      final frontCamera = _cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras.first,
      );

      _controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      _initializeControllerFuture = _controller!.initialize();

      await _initializeControllerFuture;

      setState(() {
        _isCameraReady = true;
        _feedbackMessage = "Align your face and blink";
      });

      _attemptLogin();
    } catch (e) {
      setState(() => _feedbackMessage = "Camera error: $e");
    }
  }

  Future<void> _attemptLogin() async {
    if (!_isCameraReady) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    List<File> frames = [];
    File? bestFrame;

    try {
      setState(() => _feedbackMessage = "Scanning face...");

      for (int i = 0; i < 10; i++) {
        final XFile img = await _controller!.takePicture();
        frames.add(File(img.path));
        if (i == 3) bestFrame = File(img.path);
        await Future.delayed(const Duration(milliseconds: 180));
      }

      setState(() => _feedbackMessage = "Analyzing liveness...");

      final error = await authProvider.loginWithFace(frames, bestFrame!);

      if (error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Face Login Success"),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        setState(() => _feedbackMessage = error);
      }
    } catch (e) {
      setState(() => _feedbackMessage = "Error: $e");
    } finally {
      for (var file in frames) {
        try {
          file.delete();
        } catch (_) {}
      }
    }
  }

  Widget _buildScanOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: true,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFF0E2F60).withOpacity(0.4),
              width: 2,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 1200),
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF0E2F60).withOpacity(0),
                        const Color(0xFF0E2F60).withOpacity(0.9),
                        const Color(0xFF0E2F60).withOpacity(0),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1F),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),

            Text(
              "FACE ID",
              style: TextStyle(
                fontSize: 22,
                letterSpacing: 6,
                color: const Color(0xFFFFFFFF).withOpacity(0.9),
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            Expanded(
              flex: 4,
              child: Center(
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, _) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0E2F60).withOpacity(0.4),
                              blurRadius: 30,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Stack(
                            children: [
                              _isCameraReady
                                  ? AspectRatio(
                                      aspectRatio:
                                          1 / _controller!.value.aspectRatio,
                                      child: CameraPreview(_controller!),
                                    )
                                  : const Center(
                                      child: CircularProgressIndicator(
                                        color: Color(0xFF0E2F60),
                                      ),
                                    ),

                              _buildScanOverlay(),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
                child: Column(
                  children: [
                    if (isLoading)
                      const CircularProgressIndicator(color: Color(0xFF0E2F60)),

                    const SizedBox(height: 20),

                    Text(
                      isLoading ? "PROCESSING..." : _feedbackMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFFFFFFF),
                        fontSize: 17,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      "Ensure your face is clearly visible.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
