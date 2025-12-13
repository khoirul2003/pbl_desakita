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
<<<<<<< HEAD
=======

>>>>>>> 6b47a25c040bf8bcb348cb2d034694f4993ba8cc
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
<<<<<<< HEAD
      final success = await authProvider.login(
        _emailController.text,
        _passwordController.text,
      );
=======
      final success = await authProvider.login(email, password);
>>>>>>> 6b47a25c040bf8bcb348cb2d034694f4993ba8cc
      if (success && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
<<<<<<< HEAD
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Login Gagal."), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
=======
        _showError("Email atau password salah.");
      }
    } catch (e) {
      _showError("Terjadi kesalahan: ${e.toString()}");
>>>>>>> 6b47a25c040bf8bcb348cb2d034694f4993ba8cc
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
<<<<<<< HEAD
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginFaceScreen()));
=======
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LoginFaceScreen()),
    );
>>>>>>> 6b47a25c040bf8bcb348cb2d034694f4993ba8cc
  }

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    final Color primaryBlue = const Color(0xFF0D2E5F);
    final Color cardColor = const Color(0xFFD0D6E2);

    // Ambil ukuran layar penuh perangkat
    final Size screenSize = MediaQuery.of(context).size;
    // Ambil tinggi keyboard
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      // 1. PENTING: Matikan resize otomatis agar background tidak terdorong
      resizeToAvoidBottomInset: false, 
      body: SizedBox(
        width: screenSize.width,
        height: screenSize.height,
        child: Stack(
          children: [
            // 2. BACKGROUND: Paksa ukurannya agar SELALU setinggi layar
            // Menggunakan Positioned dengan height & width eksplisit
            Positioned(
              top: 0,
              left: 0,
              width: screenSize.width,
              height: screenSize.height, // Paksa tinggi sesuai layar, bukan area sisa
              child: CustomPaint(
                painter: FullScreenWavePainter(color: primaryBlue),
=======
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
>>>>>>> 6b47a25c040bf8bcb348cb2d034694f4993ba8cc
              ),
            ),

            // 3. KONTEN (FORM):
            // Gunakan Positioned.fill dengan SingleChildScrollView di dalamnya
            Positioned.fill(
              child: SingleChildScrollView(
                // Tambahkan padding bawah sebesar tinggi keyboard agar form bisa discroll naik
                padding: EdgeInsets.only(bottom: keyboardHeight + 20),
                child: Column(
                  children: [
                    const SizedBox(height: 60),

                    // --- LOGO ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_basket_outlined, size: 50, color: primaryBlue),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Desa", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: primaryBlue, height: 1)),
                            Text("Kita", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: primaryBlue, height: 1)),
                          ],
                        )
                      ],
                    ),

                    // Jarak dinamis, gunakan persentase layar agar proporsional
                    SizedBox(height: screenSize.height * 0.15),

                    // --- FORM LOGIN ---
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
                              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text("Login", textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 25),

                                // Username
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
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                                    suffixIcon: const Icon(Icons.person_outline, color: Colors.black54),
                                  ),
                                  validator: (value) => (value == null || value.isEmpty) ? "Username wajib diisi" : null,
                                ),

                                const SizedBox(height: 16),

                                // Password
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
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                                    suffixIcon: IconButton(
                                      icon: Icon(_isObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.black54),
                                      onPressed: () => setState(() => _isObscure = !_isObscure),
                                    ),
                                  ),
                                  validator: (val) => (val != null && val.length >= 8) ? null : "Password min 8 karakter",
                                ),

                                const SizedBox(height: 30),

                                // Button
                                SizedBox(
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: _submitLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryBlue,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                    ),
                                    child: const Text("LOGIN", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 25),
                    const Text("Login dengan Wajah", style: TextStyle(color: Colors.white60, fontSize: 12)),
                    const SizedBox(height: 10),

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
                        child: const Icon(Icons.face_retouching_natural, color: Colors.white, size: 32),
                      ),
                    ),
                    const SizedBox(height: 20),

                    TextButton(
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterScreen())),
                      child: const Text("Belum punya akun? Daftar", style: TextStyle(color: Colors.white70)),
                    ),
                    const SizedBox(height: 30),
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

<<<<<<< HEAD
// PAINTER TETAP SAMA SEPERTI YANG SAYA BERIKAN SEBELUMNYA
=======
// === Painter Wave Asli (sedikit disempurnakan agar lebih natural) ===
>>>>>>> 6b47a25c040bf8bcb348cb2d034694f4993ba8cc
class FullScreenWavePainter extends CustomPainter {
  final Color color;
  FullScreenWavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
<<<<<<< HEAD
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final path = Path();
    
    // Titik awal gelombang
    path.moveTo(0, size.height * 0.38); 
    
    // Kurva gelombang
    path.quadraticBezierTo(size.width * 0.25, size.height * 0.28, size.width * 0.5, size.height * 0.38);
    path.quadraticBezierTo(size.width * 0.75, size.height * 0.48, size.width, size.height * 0.38);

    // Menutup path
    path.lineTo(size.width, size.height); 
    path.lineTo(0, size.height);          
=======
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
>>>>>>> 6b47a25c040bf8bcb348cb2d034694f4993ba8cc
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}