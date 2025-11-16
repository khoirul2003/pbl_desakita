import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:frontend/state/auth_provider.dart';

class RegisterFaceScreen extends StatefulWidget {
  const RegisterFaceScreen({super.key});

  @override
  State<RegisterFaceScreen> createState() => _RegisterFaceScreenState();
}

class _RegisterFaceScreenState extends State<RegisterFaceScreen> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 80, 
    );

    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  Future<void> _submitRegisterFace() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Harap ambil foto terlebih dahulu.")),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    
    final String? error = await authProvider.registerFace(_imageFile!);

    if (mounted) {
      if (error == null) {
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Wajah berhasil terdaftar!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(); 
      } else {
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text("Atur Login Wajah")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Ambil Foto Wajah",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              "Pastikan wajah Anda terlihat jelas dengan pencahayaan yang baik dan tanpa halangan (kacamata hitam, masker, dll).",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),

            
            Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(125), 
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 3,
                  ),
                  image: _imageFile != null
                      ? DecorationImage(
                          image: FileImage(_imageFile!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _imageFile == null
                    ? const Icon(Icons.person, size: 150, color: Colors.grey)
                    : null,
              ),
            ),
            const SizedBox(height: 24),

            
            OutlinedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: Text(_imageFile == null ? "Buka Kamera" : "Ambil Ulang"),
              onPressed: isLoading ? null : _pickImage,
            ),
            const SizedBox(height: 16),

            
            ElevatedButton.icon(
              icon: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(isLoading ? "MEMPROSES..." : "SIMPAN WAJAH"),
              onPressed: (_imageFile == null || isLoading)
                  ? null
                  : _submitRegisterFace,
            ),
          ],
        ),
      ),
    );
  }
}
