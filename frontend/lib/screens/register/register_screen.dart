import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:frontend/state/auth_provider.dart';
import 'package:frontend/screens/home/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  
  final _namaController = TextEditingController();
  final _nikController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _noKkController = TextEditingController();
  final _rtController = TextEditingController();
  final _rwController = TextEditingController();
  final _alamatController = TextEditingController();
  final _tempatLahirController = TextEditingController();
  final _tanggalLahirController =
      TextEditingController(); 
  final _agamaController = TextEditingController();
  final _statusPerkawinanController = TextEditingController();
  final _pekerjaanController = TextEditingController();

  
  String? _jenisKelaminValue;
  DateTime? _selectedDate;

  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        
        _tanggalLahirController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _submitRegister() async {
    if (!_formKey.currentState!.validate()) {
      return; 
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    
    final Map<String, dynamic> data = {
      "nama_lengkap": _namaController.text,
      "nik": _nikController.text,
      "email": _emailController.text,
      "password": _passwordController.text,
      "no_kk": _noKkController.text,
      "rt": _rtController.text,
      "rw": _rwController.text,
      "alamat": _alamatController.text,
      
      "tempat_lahir": _tempatLahirController.text,
      "tanggal_lahir": _tanggalLahirController.text,
      "jenis_kelamin": _jenisKelaminValue,
      "agama": _agamaController.text,
      "status_perkawinan": _statusPerkawinanController.text,
      "pekerjaan": _pekerjaanController.text,
    };

    try {
      final success = await authProvider.register(data);

      if (success && mounted) {
        
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Registrasi Gagal. NIK atau Email mungkin sudah terdaftar.",
            ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registrasi Warga"), centerTitle: true),
      body: Consumer<AuthProvider>(
        builder: (context, auth, child) {
          if (auth.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Buat Akun Baru",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Data Akun",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: "Email"),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => v!.isEmpty || !v.contains('@')
                        ? "Email tidak valid"
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: "Password (minimal 8 karakter)",
                    ),
                    obscureText: true,
                    validator: (v) =>
                        v!.length < 8 ? "Password minimal 8 karakter" : null,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Data Kependudukan (Sesuai KTP)",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _namaController,
                    decoration: const InputDecoration(
                      labelText: "Nama Lengkap (Sesuai KTP)",
                    ),
                    validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nikController,
                    decoration: const InputDecoration(
                      labelText: "NIK (16 Digit)",
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        v!.length != 16 ? "NIK harus 16 digit" : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _tempatLahirController,
                          decoration: const InputDecoration(
                            labelText: "Tempat Lahir",
                          ),
                          validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _tanggalLahirController,
                          decoration: const InputDecoration(
                            labelText: "Tanggal Lahir (YYYY-MM-DD)",
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          readOnly: true,
                          onTap: () => _selectDate(context),
                          validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _jenisKelaminValue,
                    decoration: const InputDecoration(
                      labelText: "Jenis Kelamin",
                    ),
                    items: const [
                      DropdownMenuItem(value: "L", child: Text("Laki-laki")),
                      DropdownMenuItem(value: "P", child: Text("Perempuan")),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _jenisKelaminValue = value;
                      });
                    },
                    validator: (v) => v == null ? "Wajib dipilih" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _agamaController,
                    decoration: const InputDecoration(labelText: "Agama"),
                    validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _statusPerkawinanController,
                    decoration: const InputDecoration(
                      labelText: "Status Perkawinan",
                    ),
                    validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _pekerjaanController,
                    decoration: const InputDecoration(labelText: "Pekerjaan"),
                    validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Data Domisili (Sesuai KK)",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _noKkController,
                    decoration: const InputDecoration(
                      labelText: "Nomor KK (Kepala Keluarga)",
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _rtController,
                          decoration: const InputDecoration(
                            labelText: "RT (mis: 001)",
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) =>
                              v!.length != 3 ? "Format 3 digit (001)" : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _rwController,
                          decoration: const InputDecoration(
                            labelText: "RW (mis: 001)",
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) =>
                              v!.length != 3 ? "Format 3 digit (001)" : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _alamatController,
                    decoration: const InputDecoration(
                      labelText: "Alamat (Sesuai KK)",
                    ),
                    validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _submitRegister,
                    child: const Text("DAFTAR"),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
