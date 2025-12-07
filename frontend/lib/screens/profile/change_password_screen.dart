import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/state/auth_provider.dart';

// --- DEFINISI WARNA PROSCAN ---
const Color _primaryColor = Color(0xFF0E2F60); // Biru Tua
const Color _backgroundColor = Color(0xFFF5F5F5); // Abu-abu muda untuk Scaffold
const Color _successColor = Color(0xFF28A745); // Hijau

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isObscureOld = true;
  bool _isObscureNew = true;
  bool _isObscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Custom Input Decoration (Gaya ProScan)
  InputDecoration _inputDecoration({required String label, required bool isObscure, required VoidCallback toggleVisibility}) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      labelStyle: const TextStyle(color: Color(0xFF3C486B)),
      suffixIcon: IconButton(
        icon: Icon(
          isObscure ? Icons.visibility_off : Icons.visibility,
          color: Colors.grey,
        ),
        onPressed: toggleVisibility,
      ),
    );
  }
  
  // --- LOGIKA SUBMIT ---
  Future<void> _submitChangePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showSnackBar("Konfirmasi password baru tidak cocok.", isError: true);
      return;
    }

    setState(() { _isLoading = true; });

    // Asumsi: ApiService memiliki fungsi changePassword
    // final apiService = context.read<ApiService>();
    
    try {
      // PENTING: Ganti dengan panggilan API yang sebenarnya:
      // final success = await apiService.changePassword(
      //   oldPassword: _oldPasswordController.text,
      //   newPassword: _newPasswordController.text,
      // );
      
      // --- SIMULASI API SUKSES ---
      await Future.delayed(const Duration(seconds: 2)); 
      final success = true; 
      // --------------------------

      if (success && mounted) {
        // Jika sukses, log out pengguna dan suruh login lagi untuk keamanan
        final authProvider = context.read<AuthProvider>();
        await authProvider.logout(); 

        _showSnackBar("Password berhasil diubah. Silakan login kembali.", isSuccess: true);
        
        // Navigasi ke halaman login
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);

      } else {
        throw Exception("Password lama salah atau gagal terhubung ke server.");
      }

    } catch (e) {
      if (mounted) {
        _showSnackBar(e.toString(), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  // Helper untuk Snackbar
  void _showSnackBar(String message, {bool isSuccess = false, bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? _successColor : isError ? Colors.red : Colors.grey,
      ),
    );
  }

  // --- WIDGET: CUSTOM HEADER PROSCAN ---
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
          const Text("Ganti Password", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Column(
        children: [
          _buildCustomHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "Perbarui Password",
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: _primaryColor),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Masukkan password lama Anda, lalu masukkan password baru Anda.",
                      style: TextStyle(fontSize: 15, color: Colors.grey),
                    ),
                    const SizedBox(height: 30),

                    // Password Lama
                    TextFormField(
                      controller: _oldPasswordController,
                      obscureText: _isObscureOld,
                      decoration: _inputDecoration(
                        label: "Password Lama",
                        isObscure: _isObscureOld,
                        toggleVisibility: () => setState(() => _isObscureOld = !_isObscureOld),
                      ),
                      validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
                    ),
                    const SizedBox(height: 16),

                    // Password Baru
                    TextFormField(
                      controller: _newPasswordController,
                      obscureText: _isObscureNew,
                      decoration: _inputDecoration(
                        label: "Password Baru",
                        isObscure: _isObscureNew,
                        toggleVisibility: () => setState(() => _isObscureNew = !_isObscureNew),
                      ),
                      validator: (v) => (v!.length < 6) ? "Minimal 6 karakter" : null,
                    ),
                    const SizedBox(height: 16),

                    // Konfirmasi Password Baru
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _isObscureConfirm,
                      decoration: _inputDecoration(
                        label: "Konfirmasi Password Baru",
                        isObscure: _isObscureConfirm,
                        toggleVisibility: () => setState(() => _isObscureConfirm = !_isObscureConfirm),
                      ),
                      validator: (v) => (v!.isEmpty) ? "Wajib diisi" : (v != _newPasswordController.text) ? "Password tidak cocok" : null,
                    ),
                    const SizedBox(height: 40),

                    // Tombol Submit
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitChangePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 5,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text("UBAH PASSWORD", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
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