import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:frontend/models/user_model.dart';
import 'package:frontend/state/auth_provider.dart';
import 'package:frontend/services/api_service.dart';

const Color _primaryColor = Color(0xFF0E2F60); // Navy Blue
const Color _accentColor = Color(0xFF4FC3F7); // Biru Aksen (diperbarui agar lebih menonjol)
const double _kBorderRadius = 12.0;

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
  
  bool _isPasswordVisible = false;
  bool _isCurrentPasswordVisible = false;

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
  
  // --- HELPER UNTUK INPUT DECORATION GAYA PROSCAN ---
  InputDecoration _proscanInputDecoration(String label, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      suffixIcon: suffixIcon,
      labelStyle: TextStyle(color: Colors.grey.shade600),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      
      // Sudut membulat
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_kBorderRadius),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_kBorderRadius),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      // Aksen Warna saat fokus
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_kBorderRadius),
        borderSide: const BorderSide(color: _accentColor, width: 2),
      ),
    );
  }

  // --- WIDGET HEADER MELENGKUNG ---
  Widget _buildCurvedHeader(BuildContext context) {
    final bool canPop = Navigator.of(context).canPop();

    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 20),
      decoration: const BoxDecoration(
        color: _primaryColor, 
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            if (canPop)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              )
            else
              const SizedBox(width: 0),

            Expanded(
              child: Text(
                "Edit Profil",
                textAlign: canPop ? TextAlign.left : TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (canPop) const SizedBox(width: 48)
          ],
        ),
      ),
    );
  }

  // --- WIDGET INPUT FIELD BARU ---
  Widget _buildField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18), // Tambah padding
      child: TextFormField(
        controller: controller,
        decoration: _proscanInputDecoration(label),
        validator: (value) {
          if (label.contains("Nama") && (value == null || value.isEmpty)) {
            return 'Nama lengkap wajib diisi.';
          }
          return null;
        },
      ),
    );
  }

  // --- WIDGET PASSWORD FIELD BARU ---
  Widget _buildPasswordField(String label, TextEditingController controller) {
    final bool isConfirm = label.contains("Konfirmasi");
    bool isVisible = isConfirm ? _isPasswordVisible : _isCurrentPasswordVisible;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: TextFormField(
        controller: controller,
        obscureText: !isVisible,
        decoration: _proscanInputDecoration(
          label,
          suffixIcon: IconButton(
            icon: Icon(
              isVisible ? Icons.visibility : Icons.visibility_off,
              color: Colors.grey,
            ),
            onPressed: () {
              setState(() {
                if (isConfirm) {
                  _isPasswordVisible = !_isPasswordVisible;
                } else {
                  _isCurrentPasswordVisible = !_isCurrentPasswordVisible;
                }
              });
            },
          ),
        ),
        validator: (value) {
          if (isConfirm && newPasswordController.text != value) {
            return 'Konfirmasi password tidak cocok.';
          }
          if (label.contains("Saat Ini") && newPasswordController.text.isNotEmpty && (value == null || value.isEmpty)) {
            return 'Password saat ini wajib diisi jika Anda ingin mengganti password.';
          }
          return null;
        },
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          _buildCurvedHeader(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20), // Padding diseragamkan
              children: [
                // --- AREA FOTO PROFIL ---
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _accentColor, width: 3),
                    ),
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
                ),
                const SizedBox(height: 16),
                
                // Tombol Aksi Foto
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: pickPhoto,
                      icon: const Icon(Icons.camera_alt, color: _primaryColor),
                      label: const Text("Ganti Foto", style: TextStyle(color: _primaryColor)),
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    ),
                    if (newProfilePhoto != null) ...[
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: uploadPhoto,
                        icon: const Icon(Icons.upload, size: 18),
                        label: const Text("Upload Foto"),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: _accentColor, 
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                          ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 30),

                // --- BAGIAN DETAIL PROFIL ---
                Text(
                  "Detail Data Diri",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
                const Divider(color: Colors.grey),
                const SizedBox(height: 10),

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

                      // --- BAGIAN GANTI PASSWORD ---
                      Text(
                        "Ganti Password",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _primaryColor,
                        ),
                      ),
                      const Divider(color: Colors.grey),
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
                // --- TOMBOL SIMPAN ---
                ElevatedButton(
                  onPressed: saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                       borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                  ),
                  child: const Text(
                    "Simpan Perubahan",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 30), // Extra space at the bottom
              ],
            ),
          ),
        ],
      ),
    );
  }
}