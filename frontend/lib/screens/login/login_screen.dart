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
    if (!_formKey.currentState!.validate()) return;
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
    }
  }

  void _goToFaceLogin() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginFaceScreen()));
  }

  @override
  Widget build(BuildContext context) {
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

// PAINTER TETAP SAMA SEPERTI YANG SAYA BERIKAN SEBELUMNYA
class FullScreenWavePainter extends CustomPainter {
  final Color color;
  FullScreenWavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
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
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}