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
  String _feedbackMessage = "Meminta izin kamera...";

  // Animation untuk efek scanning
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initCamera();

    _pulseController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.1).animate(
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
      if (mounted) {
        setState(() {
          _feedbackMessage =
              "Izin kamera ditolak. Harap izinkan di setelan HP.";
        });
      }
      return;
    }

    if (_cameras.isEmpty) {
      try {
        _cameras = await availableCameras();
      } catch (e) {
        if (mounted) {
          setState(() {
            _feedbackMessage = "Gagal mendapatkan list kamera: $e";
          });
        }
        return;
      }
    }

    if (_cameras.isEmpty) {
      if (mounted) {
        setState(() {
          _feedbackMessage = "Tidak ada kamera yang ditemukan.";
        });
      }
      return;
    }

    final frontCamera = _cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => _cameras.first,
    );

    _controller = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    _initializeControllerFuture = _controller!.initialize();

    _initializeControllerFuture!
        .then((_) {
          if (!mounted) return;
          setState(() {
            _isCameraReady = true;
            _feedbackMessage = "Arahkan wajah ke kamera dan berkedip";
          });

          _attemptLogin();
        })
        .catchError((e) {
          if (mounted) {
            setState(() {
              _feedbackMessage = "Gagal memuat kamera: $e";
            });
          }
        });
  }

  Future<void> _attemptLogin() async {
    if (!_isCameraReady || !_controller!.value.isInitialized) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Kamera belum siap.")));
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isLoading) return;

    List<File> frames = [];
    File? bestFrame;

    try {
      setState(() {
        _feedbackMessage = "Tahan... Memindai wajah Anda...";
      });

      for (int i = 0; i < 10; i++) {
        final XFile imageFile = await _controller!.takePicture();
        frames.add(File(imageFile.path));
        if (i == 3) {
          bestFrame = File(imageFile.path);
        }
        await Future.delayed(const Duration(milliseconds: 200));
      }

      setState(() {
        _feedbackMessage = "Memproses liveness dan fitur wajah...";
      });

      final String? error = await authProvider.loginWithFace(
        frames,
        bestFrame!,
      );

      if (mounted) {
        if (error == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Login Wajah Berhasil!"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        } else {
          setState(() {
            _feedbackMessage = error;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _feedbackMessage = "Error: $e";
        });
      }
    } finally {
      for (var file in frames) {
        try {
          file.delete();
        } catch (_) {}
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Face Login"),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1F1C2C),
              Color(0xFF928DAB),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),

        child: Column(
          children: [
            Expanded(
              flex: 4,
              child: Center(
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.4),
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: FutureBuilder<void>(
                            future: _initializeControllerFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                      ConnectionState.done &&
                                  _isCameraReady) {
                                return AspectRatio(
                                  aspectRatio:
                                      1 / _controller!.value.aspectRatio,
                                  child: CameraPreview(_controller!),
                                );
                              } else {
                                return const SizedBox(
                                  width: 120,
                                  height: 120,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                  ),
                                );
                              }
                            },
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
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isLoading)
                      const CircularProgressIndicator(color: Colors.white),

                    const SizedBox(height: 24),

                    Text(
                      isLoading ? "MEMPROSES..." : _feedbackMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      "Pastikan wajah terlihat jelas & pencahayaan cukup.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
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
