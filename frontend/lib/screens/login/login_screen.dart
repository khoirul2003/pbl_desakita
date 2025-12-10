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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      final success = await authProvider.login(email, password);
      if (success && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        _showError("Email atau password salah.");
      }
    } catch (e) {
      _showError("Terjadi kesalahan: ${e.toString()}");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[400],
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _goToFaceLogin() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LoginFaceScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Tetap gunakan warna asli dari desain awal
    const Color primaryBlue = Color(0xFF0D2E5F);
    const Color cardColor = Color(0xFFD0D6E2);
    const Color backgroundColor = Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Wave background asli (diperhalus)
          Positioned.fill(
            child: CustomPaint(
              painter: FullScreenWavePainter(color: primaryBlue),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 70),

                  // === LOGO (asli, diperhalus spacing) ===
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_basket_outlined, size: 48, color: primaryBlue),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Desa",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: primaryBlue,
                            ),
                          ),
                          Text(
                            "Kita",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: primaryBlue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  SizedBox(height: MediaQuery.of(context).size.height * 0.12),

                  // === FORM CARD (asli, tapi lebih rapi) ===
                  Consumer<AuthProvider>(
                    builder: (context, auth, child) {
                      if (auth.isLoading) {
                        return const Center(child: CircularProgressIndicator(color: Colors.white));
                      }

                      return Container(
                        padding: const EdgeInsets.all(26),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
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
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Email
                              const Text("Email", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 5),
                              TextFormField(
                                controller: _emailController,
                                decoration: InputDecoration(
                                  hintText: "Masukkan email Anda",
                                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                                  filled: true,
                                  fillColor: const Color(0xFFEBEFF5),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: BorderSide.none,
                                  ),
                                  prefixIcon: const Icon(Icons.email_outlined, color: Colors.black54),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "Email wajib diisi";
                                  }
                                  final emailRegExp = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                                  if (!emailRegExp.hasMatch(value)) {
                                    return "Format email tidak valid";
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 16),

                              // Password
                              const Text("Password", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 5),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _isObscure,
                                decoration: InputDecoration(
                                  hintText: "Masukkan password Anda",
                                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                                  filled: true,
                                  fillColor: const Color(0xFFEBEFF5),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: BorderSide.none,
                                  ),
                                  prefixIcon: const Icon(Icons.lock_outline, color: Colors.black54),
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
                                  if (value == null || value.isEmpty) {
                                    return "Password wajib diisi";
                                  }
                                  if (value.length < 8) {
                                    return "Password minimal 8 karakter";
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 30),

                              // Login Button
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

                  const SizedBox(height: 32),

                  // === LOGIN WITH FACE (tetap di atas wave) ===
                  Text(
                    "Login dengan Wajah",
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _goToFaceLogin,
                    customBorder: const CircleBorder(),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        color: Colors.white.withOpacity(0.15),
                      ),
                      child: const Icon(
                        Icons.face_retouching_natural,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // === REGISTER LINK (tetap putih lembut, karena di atas wave biru) ===
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      );
                    },
                    child: const Text(
                      "Belum punya akun? Daftar",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
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

// === Painter Wave Asli (sedikit disempurnakan agar lebih natural) ===
class FullScreenWavePainter extends CustomPainter {
  final Color color;

  FullScreenWavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();

    // Mulai dari ~40% tinggi layar (lebih rendah dari sebelumnya)
    path.moveTo(0, size.height * 0.42);
    path.quadraticBezierTo(
      size.width * 0.25, size.height * 0.32,
      size.width * 0.5, size.height * 0.42,
    );
    path.quadraticBezierTo(
      size.width * 0.75, size.height * 0.52,
      size.width, size.height * 0.42,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}