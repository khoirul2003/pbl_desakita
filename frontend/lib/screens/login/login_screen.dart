import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:frontend/state/auth_provider.dart';
import 'package:frontend/screens/home/home_screen.dart';
import 'package:frontend/screens/register/register_screen.dart';
import 'package:frontend/screens/wajah/login_face_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isObscure = true;

  Future<void> _submitLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      final success = await authProvider.login(
        _emailController.text,
        _passwordController.text,
      );

      if (success && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Login Gagal. Cek email dan password."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Terjadi kesalahan: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _goToFaceLogin() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LoginFaceScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = const Color(0xFF0D2E5F); 
    final Color cardColor = const Color(0xFFD0D6E2); 

    return Scaffold(
      // PERBAIKAN 1: Ubah background scaffold jadi Putih
      // Ini menghilangkan kebutuhan akan Container putih di atas yang menyebabkan garis
      backgroundColor: Colors.white, 
      body: Stack(
        children: [
          // PERBAIKAN 2: Gunakan CustomPaint yang mengisi layar penuh (Positioned.fill)
          // Painter ini akan menggambar blok Biru dari bawah ke tengah (Wave)
          // Tanpa tumpukan container, garis putih dijamin hilang.
          Positioned.fill(
            child: CustomPaint(
              painter: FullScreenWavePainter(color: primaryBlue),
            ),
          ),

          // Konten Utama (Logo & Form)
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  
                  // LOGO SECTION 
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_basket_outlined, size: 50, color: primaryBlue),
                      const SizedBox(width: 10),
   Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Rukun",
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: primaryBlue,
                              height: 1,
                            ),
                          ),
                          Text(
                            "App",
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: primaryBlue,
                              height: 1,
                            ),
                          ),
                        ],
                      )
                    ],
                  ),

                  SizedBox(height: MediaQuery.of(context).size.height * 0.15),

                  // FORM CARD SECTION
                  Consumer<AuthProvider>(
                    builder: (context, auth, child) {
                      if (auth.isLoading) {
                        return const Center(child: CircularProgressIndicator(color: Colors.white));
                      }

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 24),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            )
                          ],
