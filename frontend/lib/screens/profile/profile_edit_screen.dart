import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:frontend/models/user_model.dart';
import 'package:frontend/state/auth_provider.dart';
import 'package:frontend/services/api_service.dart';

const Color _primaryColor = Color(0xFF0E2F60);
const Color _accentColor = Color(0xFF3C486B);

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();

  File? newProfilePhoto;
  String? currentPhotoUrl;

  late TextEditingController namaController;
  late TextEditingController noHpController;
  late TextEditingController alamatKtpController;
  late TextEditingController tempatLahirController;
  late TextEditingController tanggalLahirController;
  late TextEditingController agamaController;
  late TextEditingController statusPerkawinanController;
  late TextEditingController pekerjaanController;

  late TextEditingController currentPasswordController;
  late TextEditingController newPasswordController;
  late TextEditingController confirmPasswordController;

  @override
  void initState() {
    super.initState();

    final user = context.read<AuthProvider>().user!;
    final warga = user.warga!;

    currentPhotoUrl = warga.fotoKtp;

    namaController = TextEditingController(text: warga.namaLengkap);
    noHpController = TextEditingController(text: warga.noHp ?? "");
    alamatKtpController = TextEditingController(text: warga.alamatKtp ?? "");
    tempatLahirController = TextEditingController(
      text: warga.tempatLahir ?? "",
    );
    tanggalLahirController = TextEditingController(
      text: warga.tanggalLahir ?? "",
    );
    agamaController = TextEditingController(text: warga.agama ?? "");
    statusPerkawinanController = TextEditingController(
      text: warga.statusPerkawinan ?? "",
    );
    pekerjaanController = TextEditingController(text: warga.pekerjaan ?? "");

    currentPasswordController = TextEditingController();
    newPasswordController = TextEditingController();
    confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    namaController.dispose();
    noHpController.dispose();
    alamatKtpController.dispose();
    tempatLahirController.dispose();
    tanggalLahirController.dispose();
    agamaController.dispose();
    statusPerkawinanController.dispose();
    pekerjaanController.dispose();

    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();

    super.dispose();
  }

  Future<void> pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        newProfilePhoto = File(picked.path);
      });
    }
  }

  Future<void> uploadPhoto() async {
    if (newProfilePhoto == null) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.updateProfilePhoto(newProfilePhoto!);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Foto profil berhasil diperbarui."),
          backgroundColor: Colors.green,
        ),
      );

      newProfilePhoto = null;
      await auth.refreshUserProfile();

      setState(() {
        currentPhotoUrl = auth.user!.warga!.fotoKtp;
      });
    }
  }

  Future<void> saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final payload = {
      'nama_lengkap': namaController.text,
      'no_hp': noHpController.text,
      'alamat_ktp': alamatKtpController.text,
      'tempat_lahir': tempatLahirController.text,
      'tanggal_lahir': tanggalLahirController.text,
      'agama': agamaController.text,
      'status_perkawinan': statusPerkawinanController.text,
      'pekerjaan': pekerjaanController.text,
    };

    if (newPasswordController.text.isNotEmpty) {
      payload['current_password'] = currentPasswordController.text;
      payload['new_password'] = newPasswordController.text;
      payload['new_password_confirmation'] = confirmPasswordController.text;
    }

    final api = ApiService();
    try {
      final res = await api.updateProfile(payload);
      if (res != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Profil berhasil diperbarui."),
              backgroundColor: Colors.green,
            ),
          );
          await context.read<AuthProvider>().refreshUserProfile();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal update profil: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profil"),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: CircleAvatar(
              radius: 55,
              backgroundColor: Colors.grey[300],
              backgroundImage: newProfilePhoto != null
                  ? FileImage(newProfilePhoto!)
                  : (currentPhotoUrl != null
                            ? NetworkImage(currentPhotoUrl!)
                            : null)
                        as ImageProvider?,
              child: (newProfilePhoto == null && currentPhotoUrl == null)
                  ? const Icon(Icons.person, size: 50, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: pickPhoto,
            icon: const Icon(Icons.photo_camera),
            label: const Text("Ganti Foto Profil"),
          ),
          if (newProfilePhoto != null)
            ElevatedButton(
              onPressed: uploadPhoto,
              style: ElevatedButton.styleFrom(backgroundColor: _primaryColor),
              child: const Text("Upload Foto"),
            ),
          const SizedBox(height: 20),

          Form(
            key: _formKey,
            child: Column(
              children: [
                _buildField("Nama Lengkap", namaController),
                _buildField("No HP", noHpController),
                _buildField("Alamat KTP", alamatKtpController),
                _buildField("Tempat Lahir", tempatLahirController),
                _buildField(
                  "Tanggal Lahir (YYYY-MM-DD)",
                  tanggalLahirController,
                ),
                _buildField("Agama", agamaController),
                _buildField("Status Perkawinan", statusPerkawinanController),
                _buildField("Pekerjaan", pekerjaanController),
                const SizedBox(height: 30),

                Text(
                  "Ganti Password",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _accentColor,
                  ),
                ),
                const SizedBox(height: 10),

                _buildPasswordField(
                  "Password Saat Ini",
                  currentPasswordController,
                ),
                _buildPasswordField("Password Baru", newPasswordController),
                _buildPasswordField(
                  "Konfirmasi Password Baru",
                  confirmPasswordController,
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: saveProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text(
              "Simpan Perubahan",
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        obscureText: true,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
