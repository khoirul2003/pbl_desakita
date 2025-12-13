import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/state/auth_provider.dart';
import 'package:frontend/screens/home/home_screen.dart';
import 'package:flutter/services.dart'; // Untuk FilteringTextInputFormatter

// --- DEFINISI WARNA PROSCAN ---
const Color _primaryColor = Color(0xFF0E2F60); 
const Color _backgroundColor = Color(0xFFF5F5F5); 
const Color _accentColor = Color(0xFF3C486B); 
const Color _successColor = Color(0xFF28A745); 

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
  final _tanggalLahirController = TextEditingController();
  final _agamaController = TextEditingController();
  final _statusPerkawinanController = TextEditingController();
  final _pekerjaanController = TextEditingController();

  String? _jenisKelaminValue;
  DateTime? _selectedDate;

  // State untuk Expansion Tile (opsional, tapi bagus untuk UX)
  bool _isExpanded1 = true;
  bool _isExpanded2 = false;
  bool _isExpanded3 = false;
  
  // Custom Input Decoration (Gaya ProScan)
  final InputDecoration _inputDecoration = InputDecoration(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    labelStyle: const TextStyle(color: _accentColor),
  );

  @override
  void dispose() {
    _namaController.dispose();
    _nikController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _noKkController.dispose();
    _rtController.dispose();
    _rwController.dispose();
    _alamatController.dispose();
    _tempatLahirController.dispose();
    _tanggalLahirController.dispose();
    _agamaController.dispose();
    _statusPerkawinanController.dispose();
    _pekerjaanController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().subtract(const Duration(days: 365 * 20)),
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
      // Fokus pada expansion tile yang gagal validasi
      if (!_isExpanded1 && (_emailController.text.isEmpty || _passwordController.text.length < 8 || _nikController.text.length != 16)) {
        setState(() => _isExpanded1 = true);
      } else if (!_isExpanded2 && (_namaController.text.isEmpty || _tempatLahirController.text.isEmpty)) {
        setState(() => _isExpanded2 = true);
      } else if (!_isExpanded3 && (_noKkController.text.isEmpty || _rtController.text.length != 3 || _rwController.text.length != 3)) {
        setState(() => _isExpanded3 = true);
      }
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Registrasi berhasil!"),
            backgroundColor: _successColor,
          ),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Registrasi Gagal. NIK atau Email mungkin sudah terdaftar."),
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
  
  // --- WIDGET BANTUAN: SECTION EXPANSION TILE ---
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
              children: fields,
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET: HEADER APP BAR CUSTOM ---
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
          const Text("Registrasi Akun Warga", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

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
                    // --- 1. DATA AKUN ---
                    _buildSectionTile(
                      title: "Data Akun & Login",
                      isExpanded: _isExpanded1,
                      onChanged: (val) => setState(() => _isExpanded1 = val),
                      fields: [
                        TextFormField(
                          controller: _emailController,
                          decoration: _inputDecoration.copyWith(labelText: "Email"),
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) => v!.isEmpty || !v.contains('@') ? "Email tidak valid" : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          decoration: _inputDecoration.copyWith(
                            labelText: "Password (min. 8 karakter)",
                          ),
                          obscureText: true,
                          validator: (v) => v!.length < 8 ? "Password minimal 8 karakter" : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nikController,
                          decoration: _inputDecoration.copyWith(labelText: "NIK (16 Digit)"),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (v) => v!.length != 16 ? "NIK harus 16 digit" : null,
                        ),
                      ],
                    ),
                    
                    // --- 2. DATA KEPENDUDUKAN ---
                    _buildSectionTile(
                      title: "Data Kependudukan (Sesuai KTP)",
                      isExpanded: _isExpanded2,
                      onChanged: (val) => setState(() => _isExpanded2 = val),
                      fields: [
                        TextFormField(
                          controller: _namaController,
                          decoration: _inputDecoration.copyWith(labelText: "Nama Lengkap"),
                          validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _tempatLahirController,
                                decoration: _inputDecoration.copyWith(labelText: "Tempat Lahir"),
                                validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _tanggalLahirController,
                                decoration: _inputDecoration.copyWith(
                                  labelText: "Tanggal Lahir",
                                  suffixIcon: const Icon(Icons.calendar_today, color: _accentColor),
                                ),
                                readOnly: true,
                                onTap: () => isLoading ? null : _selectDate(context),
                                validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _jenisKelaminValue,
                          decoration: _inputDecoration.copyWith(labelText: "Jenis Kelamin"),
                          items: const [
                            DropdownMenuItem(value: "L", child: Text("Laki-laki")),
                            DropdownMenuItem(value: "P", child: Text("Perempuan")),
                          ],
                          onChanged: (value) { setState(() => _jenisKelaminValue = value); },
                          validator: (v) => v == null ? "Wajib dipilih" : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _agamaController,
                          decoration: _inputDecoration.copyWith(labelText: "Agama"),
                          validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _statusPerkawinanController,
                          decoration: _inputDecoration.copyWith(labelText: "Status Perkawinan"),
                          validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _pekerjaanController,
                          decoration: _inputDecoration.copyWith(labelText: "Pekerjaan"),
                          validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
                        ),
                      ],
                    ),
                    
                    // --- 3. DATA DOMISILI ---
                    _buildSectionTile(
                      title: "Data Domisili (Sesuai KK)",
                      isExpanded: _isExpanded3,
                      onChanged: (val) => setState(() => _isExpanded3 = val),
                      fields: [
                        TextFormField(
                          controller: _noKkController,
                          decoration: _inputDecoration.copyWith(labelText: "Nomor KK (Kepala Keluarga)"),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _rtController,
                                decoration: _inputDecoration.copyWith(labelText: "RT (mis: 001)", counterText: ""),
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                maxLength: 3,
                                validator: (v) => (v!.length != 3 || v.isEmpty) ? "Format 3 digit (001)" : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _rwController,
                                decoration: _inputDecoration.copyWith(labelText: "RW (mis: 001)", counterText: ""),
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                maxLength: 3,
                                validator: (v) => (v!.length != 3 || v.isEmpty) ? "Format 3 digit (001)" : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _alamatController,
                          decoration: _inputDecoration.copyWith(labelText: "Alamat (Sesuai KK)"),
                          validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),
                    
                    // --- TOMBOL DAFTAR ---
                    ElevatedButton(
                      onPressed: isLoading ? null : _submitRegister,
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
                              "DAFTAR", 
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