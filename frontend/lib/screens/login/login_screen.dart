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
