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
                       ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                "Login",
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 25),

                              // Username Input
                              const Text("username", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 5),
                              TextFormField(
                                controller: _emailController,
                                decoration: InputDecoration(
                                  hintText: "please input your username",
                                  hintStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
                                  filled: true,
                                  fillColor: const Color(0xFFEBEFF5),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: BorderSide.none,
                                  ),
                                  suffixIcon: const Icon(Icons.person_outline, color: Colors.black54),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty || !value.contains('@')) {
                                    return "Masukkan email yang valid";
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 16),

                              // Password Input
                              const Text("password", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 5),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _isObscure,
                                decoration: InputDecoration(
                                  hintText: "please input your password",
                                  hintStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
                                  filled: true,
                                  fillColor: const Color(0xFFEBEFF5),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: BorderSide.none,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                      color: Colors.black54,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isObscure = !_isObscure;
                                      });
                                    },
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty || value.length < 8) {
                                    return "Password minimal 8 karakter";
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 30),

                              // LOGIN BUTTON
                              SizedBox(
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _submitLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryBlue,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                    ),
                                    elevation: 2,
                                  ),
                                  child: const Text(
                                    "LOGIN",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  
                  // Footer Links
                  const SizedBox(height: 25),
                  
                  const Text(
                    "Login dengan Wajah", 
                    style: TextStyle(color: Colors.white60, fontSize: 12)
                  ),
                  const SizedBox(height: 10),

                  // Tombol Icon Wajah
                  InkWell(
                    onTap: _goToFaceLogin,
                    customBorder: const CircleBorder(),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        color: Colors.white.withOpacity(0.1), 
                      ),
                      child: const Icon(
                        Icons.face_retouching_natural,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
          const SizedBox(height: 20),
                  
                   TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      );
                    },
                    child: const Text(
                      "Belum punya akun? Daftar", 
                      style: TextStyle(color: Colors.white70)
                    ),
                  ),
                  const SizedBox(height: 30), 
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// PERBAIKAN 3: Painter yang diperbarui (FullScreenWavePainter)
// Painter ini sekarang menggambar satu blok utuh berwarna biru dari 
// tengah layar sampai ke paling bawah.
class FullScreenWavePainter extends CustomPainter {
  final Color color;

  FullScreenWavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    
    // Titik awal gelombang (Kiri, sekitar 38% dari atas layar)
    path.moveTo(0, size.height * 0.38); 
    
    // Membuat kurva gelombang
    path.quadraticBezierTo(
      size.width * 0.25, size.height * 0.28, // Control point naik
      size.width * 0.5, size.height * 0.38   // Titik tengah
    );
    path.quadraticBezierTo(
      size.width * 0.75, size.height * 0.48, // Control point turun
      size.width, size.height * 0.38         // Titik akhir kanan
    );

    // Menutup path ke pojok kanan bawah dan kiri bawah
    path.lineTo(size.width, size.height); 
    path.lineTo(0, size.height);          
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

