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

class _LoginFaceScreenState extends State<LoginFaceScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isCameraReady = false;
  String _feedbackMessage = "Meminta izin kamera...";

  @override
  void initState() {
    super.initState();
    _initCamera();
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

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
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

      for (int i = 0; i < 6; i++) {
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
        } catch (e) {
          print("Gagal hapus file frame: $e");
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text("Login dengan Wajah")),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: Container(
              color: Colors.black,
              child: FutureBuilder<void>(
                future: _initializeControllerFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done &&
                      _isCameraReady) {
                    return Center(
                      child: AspectRatio(
                        aspectRatio: 1 / _controller!.value.aspectRatio,
                        child: CameraPreview(_controller!),
                      ),
                    );
                  } else {
                    return const Center(child: CircularProgressIndicator());
                  }
                },
              ),
            ),
          ),

          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    const SizedBox(height: 24),

                  const SizedBox(height: 24),

                  Text(
                    isLoading ? "MEMPROSES..." : _feedbackMessage,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
