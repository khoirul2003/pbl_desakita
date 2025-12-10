import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

// Import model dan service yang diperlukan (sesuaikan path Anda)
import 'package:frontend/models/user_model.dart';
import 'package:frontend/state/auth_provider.dart';
import 'package:frontend/services/api_service.dart';

// --- KONSTANTA GAYA (Diambil dari kode yang Anda kirimkan) ---
const Color _primaryColor = Color(0xFF0E2F60); // Navy Blue
const Color _backgroundColor = Color(0xFFF5F5F5); 
const Color _accentColor = Color(0xFF3C486B); // Aksen Biru/Abu-abu gelap
const Color _successColor = Color(0xFF28A745); 

// Custom Input Decoration (Gaya ProScan dari kode Anda)
final InputDecoration _inputDecoration = InputDecoration(
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide.none,
  ),
  filled: true,
  fillColor: Colors.white,
  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
  labelStyle: const TextStyle(color: _accentColor),
  // Tambahkan floatingLabelBehavior agar label selalu berada di atas, 
  // mencegah tumpang tindih dengan teks field yang terisi.
  floatingLabelBehavior: FloatingLabelBehavior.auto,
);

// --- CLASS UTAMA ---
class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();

  // State untuk Foto
  File? newProfilePhoto;
  String? currentPhotoUrl;
  bool _isUploadingPhoto = false;

  // State untuk Input Data Diri
  late TextEditingController namaController;
  late TextEditingController noHpController;
  late TextEditingController alamatKtpController;
  late TextEditingController tempatLahirController;
  late TextEditingController tanggalLahirController;
  late TextEditingController agamaController;
  late TextEditingController statusPerkawinanController;
  late TextEditingController pekerjaanController;

  // State untuk Ganti Password
  late TextEditingController currentPasswordController;
  late TextEditingController newPasswordController;
  late TextEditingController confirmPasswordController;
  bool _isPasswordVisible = false;
  bool _isCurrentPasswordVisible = false;
  bool _isSavingProfile = false;
  
  // State untuk Expansion Tile
  bool _isExpanded1 = true;
  bool _isExpanded2 = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final user = context.read<AuthProvider>().user!;
    final warga = user.warga!;

    currentPhotoUrl = warga.fotoKtp; 

    namaController = TextEditingController(text: warga.namaLengkap);
    noHpController = TextEditingController(text: warga.noHp ?? "");
    alamatKtpController = TextEditingController(text: warga.alamatKtp ?? "");
    tempatLahirController = TextEditingController(text: warga.tempatLahir ?? "");
    tanggalLahirController = TextEditingController(text: warga.tanggalLahir ?? "");
    agamaController = TextEditingController(text: warga.agama ?? "");
    statusPerkawinanController = TextEditingController(text: warga.statusPerkawinan ?? "");
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
  
  // --- LOGIKA DATE PICKER ---
  Future<void> _selectDate(BuildContext context) async {
    final initialDate = tanggalLahirController.text.isNotEmpty 
      ? DateTime.tryParse(tanggalLahirController.text) ?? DateTime.now().subtract(const Duration(days: 365 * 20))
      : DateTime.now().subtract(const Duration(days: 365 * 20));

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primaryColor, 
              onPrimary: Colors.white,
              onSurface: _primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        tanggalLahirController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  // --- LOGIKA UPLOAD FOTO (Tidak Berubah) ---
  Future<void> pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

    if (picked != null) {
      setState(() {
        newProfilePhoto = File(picked.path);
      });
    }
  }

  Future<void> uploadPhoto() async {
    if (newProfilePhoto == null) return;
    
    setState(() => _isUploadingPhoto = true);

    try {
      final auth = context.read<AuthProvider>();
      final success = await auth.updateProfilePhoto(newProfilePhoto!);

      if (success && mounted) {
        newProfilePhoto = null;
        await auth.refreshUserProfile();

        setState(() {
          currentPhotoUrl = auth.user!.warga!.fotoKtp;
          _isUploadingPhoto = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Foto profil berhasil diperbarui."),
            backgroundColor: _successColor,
          ),
        );
      } else {
         setState(() => _isUploadingPhoto = false);
      }
    } catch (e) {
       if (mounted) {
        setState(() => _isUploadingPhoto = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal upload foto: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
       }
    }
  }

  // --- LOGIKA SIMPAN PROFIL (Tidak Berubah) ---
  Future<void> saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      if (!_isExpanded1 && (namaController.text.isEmpty || alamatKtpController.text.isEmpty)) {
        setState(() => _isExpanded1 = true);
      }
      return;
    }
    
    setState(() => _isSavingProfile = true);

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
      
      if (mounted) {
        setState(() => _isSavingProfile = false);
        if (res != null) {
          currentPasswordController.clear();
          newPasswordController.clear();
          confirmPasswordController.clear();
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Profil berhasil diperbarui."),
              backgroundColor: _successColor,
            ),
          );
          await context.read<AuthProvider>().refreshUserProfile();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSavingProfile = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal update profil: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- WIDGET BANTUAN: SECTION EXPANSION TILE (Diperbaiki) ---
  Widget _buildSectionTile({
    required String title, 
    required List<Widget> fields, 
    required bool isExpanded,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        initiallyExpanded: isExpanded,
        onExpansionChanged: onChanged,
        tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: _primaryColor,
          ),
        ),
        collapsedIconColor: _accentColor,
        iconColor: _primaryColor,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // *** PERBAIKAN DI SINI: MENAMBAH JARAK VERTIKAL ***
                const SizedBox(height: 8), 
                ...fields,
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET: HEADER APP BAR CUSTOM (Tidak Berubah) ---
  Widget _buildCustomHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8, left: 16, right: 16, bottom: 16,
      ),
      decoration: const BoxDecoration(
        color: _primaryColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white), 
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          const Text("Edit Profil", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // --- WIDGET: TEXT FIELD UTAMA (Tidak Berubah) ---
  Widget _buildTextField(String label, TextEditingController controller, {bool isRequired = false, TextInputType keyboardType = TextInputType.text, Widget? suffixIcon, bool readOnly = false, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: _inputDecoration.copyWith(
          labelText: label,
          suffixIcon: suffixIcon,
        ),
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        validator: (v) {
          if (isRequired && (v == null || v.isEmpty)) {
            return '$label wajib diisi.';
          }
          return null;
        },
      ),
    );
  }

  // --- WIDGET: PASSWORD FIELD (Tidak Berubah) ---
  Widget _buildPasswordField(String label, TextEditingController controller, bool isVisible, bool isCurrentPassword, {required TextEditingController newPasswordController}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: !isVisible,
        decoration: _inputDecoration.copyWith(
          labelText: label,
          suffixIcon: IconButton(
            icon: Icon(
              isVisible ? Icons.visibility : Icons.visibility_off,
              color: _accentColor,
            ),
            onPressed: () {
              setState(() {
                if (isCurrentPassword) {
                  _isCurrentPasswordVisible = !_isCurrentPasswordVisible;
                } else {
                  _isPasswordVisible = !_isPasswordVisible;
                }
              });
            },
          ),
        ),
        validator: (v) {
          if (label.contains("Konfirmasi") && newPasswordController.text != v) {
            return 'Konfirmasi password tidak cocok.';
          }
          if (isCurrentPassword && newPasswordController.text.isNotEmpty && (v == null || v.isEmpty)) {
            return 'Password saat ini wajib diisi jika Anda ingin mengganti password.';
          }
          return null;
        },
      ),
    );
  }

  // --- WIDGET UNTUK SECTION FOTO PROFIL (Tidak Berubah) ---
  Widget _buildProfilePictureSection() {
    return Column(
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _primaryColor, width: 3),
            ),
            child: CircleAvatar(
              radius: 55,
              backgroundColor: Colors.grey[300],
              backgroundImage: newProfilePhoto != null
                  ? FileImage(newProfilePhoto!)
                  : (currentPhotoUrl != null
                      ? NetworkImage(currentPhotoUrl!)
                      : null) as ImageProvider?,
              child: (newProfilePhoto == null && currentPhotoUrl == null)
                  ? const Icon(Icons.person, size: 50, color: Colors.white)
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              onPressed: _isUploadingPhoto ? null : pickPhoto,
              icon: Icon(Icons.camera_alt, color: _isUploadingPhoto ? Colors.grey : _accentColor),
              label: Text("Ganti Foto", style: TextStyle(color: _isUploadingPhoto ? Colors.grey : _accentColor)),
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
            ),
            if (newProfilePhoto != null) ...[
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _isUploadingPhoto ? null : uploadPhoto,
                icon: _isUploadingPhoto 
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.upload, size: 18),
                label: Text(_isUploadingPhoto ? "Mengunggah..." : "Upload Foto"),
                style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor, 
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 3,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  // --- WIDGET UTAMA BUILD (Tidak Berubah) ---
  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading || _isSavingProfile;

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Column(
        children: [
          _buildCustomHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- AREA FOTO PROFIL ---
                    _buildProfilePictureSection(),
                    const SizedBox(height: 30),

                    // --- 1. DATA DIRI KTP ---
                    _buildSectionTile(
                      title: "Data Diri (Sesuai KTP)",
                      isExpanded: _isExpanded1,
                      onChanged: (val) => setState(() => _isExpanded1 = val),
                      fields: [
                        _buildTextField("Nama Lengkap", namaController, isRequired: true),
                        _buildTextField("No HP", noHpController, keyboardType: TextInputType.phone),
                        _buildTextField("Alamat KTP", alamatKtpController, isRequired: true),
                        _buildTextField("Tempat Lahir", tempatLahirController, isRequired: true),
                        _buildTextField(
                          "Tanggal Lahir (YYYY-MM-DD)",
                          tanggalLahirController,
                          isRequired: true,
                          readOnly: true,
                          onTap: isLoading ? null : () => _selectDate(context),
                          suffixIcon: const Icon(Icons.calendar_today, color: _accentColor),
                        ),
                        _buildTextField("Agama", agamaController, isRequired: true),
                        _buildTextField("Status Perkawinan", statusPerkawinanController, isRequired: true),
                        _buildTextField("Pekerjaan", pekerjaanController, isRequired: true),
                      ],
                    ),
                    
                    // --- 2. GANTI PASSWORD ---
                    _buildSectionTile(
                      title: "Ganti Password",
                      isExpanded: _isExpanded2,
                      onChanged: (val) => setState(() => _isExpanded2 = val),
                      fields: [
                        _buildPasswordField(
                          "Password Saat Ini",
                          currentPasswordController,
                          _isCurrentPasswordVisible,
                          true,
                          newPasswordController: newPasswordController,
                        ),
                        _buildPasswordField(
                          "Password Baru",
                          newPasswordController,
                          _isPasswordVisible,
                          false,
                          newPasswordController: newPasswordController,
                        ),
                        _buildPasswordField(
                          "Konfirmasi Password Baru",
                          confirmPasswordController,
                          _isPasswordVisible,
                          false,
                          newPasswordController: newPasswordController,
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),
                    
                    // --- TOMBOL SIMPAN ---
                    ElevatedButton(
                      onPressed: isLoading ? null : saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 5,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text(
                              "SIMPAN PERUBAHAN", 
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}