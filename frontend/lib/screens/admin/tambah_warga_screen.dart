import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:frontend/services/api_service.dart';
import 'package:frontend/models/user_model.dart';

const Color _primaryColor = Color(0xFF0E2F60);
const Color _backgroundColor = Color(0xFFF5F5F5);
const Color _accentColor = Color(0xFF3C486B);

class TambahWargaScreen extends StatefulWidget {
  const TambahWargaScreen({super.key});

  @override
  State<TambahWargaScreen> createState() => _TambahWargaScreenState();
}

class _TambahWargaScreenState extends State<TambahWargaScreen> {
  final _formKey = GlobalKey<FormState>();

  // ================= CONTROLLER =================
  final _namaController = TextEditingController();
  final _nikController = TextEditingController();
  final _tempatLahirController = TextEditingController();
  final _tanggalLahirController = TextEditingController();
  final _agamaController = TextEditingController();
  final _statusPerkawinanController = TextEditingController();
  final _pekerjaanController = TextEditingController();
  final _alamatKtpController = TextEditingController();
  final _noHpController = TextEditingController();
  final _rtController = TextEditingController();
  final _rwController = TextEditingController();

  // ================= EMAIL AND PASSWORD CONTROLLERS =================
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // ================= STATE =================
  String? _jenisKelamin;
  String? _statusDalamKeluarga;
  int? _selectedKeluargaId;

  List<Keluarga> _keluargaList = [];

  bool _isLoading = false;

  final InputDecoration _inputDecoration = InputDecoration(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    labelStyle: const TextStyle(color: _accentColor),
  );

  // ================= INIT =================
  @override
  void initState() {
    super.initState();
    _loadKeluarga();
  }

  @override
  void dispose() {
    _namaController.dispose();
    _nikController.dispose();
    _tempatLahirController.dispose();
    _tanggalLahirController.dispose();
    _agamaController.dispose();
    _statusPerkawinanController.dispose();
    _pekerjaanController.dispose();
    _alamatKtpController.dispose();
    _noHpController.dispose();
    _rtController.dispose();
    _rwController.dispose();
    _emailController.dispose(); // Dispose email controller
    _passwordController.dispose(); // Dispose password controller
    super.dispose();
  }

  // ================= API =================
  Future<void> _loadKeluarga() async {
    final api = context.read<ApiService>();
    final list = await api.getAllKeluarga();
    setState(() => _keluargaList = list);
  }

  // ================= DATE =================
  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      _tanggalLahirController.text =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
    }
  }

  // ================= SUBMIT =================
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final api = context.read<ApiService>();

    final data = {
      "nama_lengkap": _namaController.text,
      "nik": _nikController.text,
      "tempat_lahir": _tempatLahirController.text,
      "tanggal_lahir": _tanggalLahirController.text,
      "jenis_kelamin": _jenisKelamin,
      "agama": _agamaController.text,
      "status_perkawinan": _statusPerkawinanController.text,
      "pekerjaan": _pekerjaanController.text,
      "alamat_ktp": _alamatKtpController.text,
      "no_hp": _noHpController.text.isEmpty ? null : _noHpController.text,
      "kewarganegaraan": "WNI",
      "rt": _rtController.text,
      "rw": _rwController.text,
      "keluarga_id": _selectedKeluargaId,
      "status_dalam_keluarga": _statusDalamKeluarga,
      "email": _emailController.text, // Added email
      "password": _passwordController.text, // Added password
    };

    try {
      final res = await api.createManajemenWarga(data);
      if (mounted && res != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Warga berhasil ditambahkan"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal menambah warga: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        title: const Text("Tambah Warga"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _text(_namaController, "Nama Lengkap"),
              _text(_nikController, "NIK", number: true, length: 16),
              _text(_tempatLahirController, "Tempat Lahir"),
              _dateField(),
              _dropdown(
                label: "Jenis Kelamin",
                value: _jenisKelamin,
                items: const ["L", "P"],
                onChanged: (v) => setState(() => _jenisKelamin = v),
              ),
              _text(_agamaController, "Agama"),
              _text(_statusPerkawinanController, "Status Perkawinan"),
              _text(_pekerjaanController, "Pekerjaan"),
              _text(_noHpController, "No HP (Opsional)", number: true),
              _text(_alamatKtpController, "Alamat KTP", multi: true),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _text(
                      _rtController,
                      "RT (001)",
                      number: true,
                      length: 3,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _text(
                      _rwController,
                      "RW (001)",
                      number: true,
                      length: 3,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              DropdownButtonFormField<int>(
                value: _selectedKeluargaId,
                decoration: _inputDecoration.copyWith(
                  labelText: "Keluarga (No KK)",
                ),
                items: _keluargaList
                    .map(
                      (k) => DropdownMenuItem<int>(
                        value: k.id,
                        child: Text(k.noKk),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedKeluargaId = v),
                validator: (v) => v == null ? "Wajib dipilih" : null,
              ),

              const SizedBox(height: 12),

              _dropdown(
                label: "Status Dalam Keluarga",
                value: _statusDalamKeluarga,
                items: const ["KEPALA_KELUARGA", "ISTRI", "ANAK", "LAINNYA"],
                onChanged: (v) => setState(() => _statusDalamKeluarga = v),
              ),

              const SizedBox(height: 12),

              // Email and Password Input Fields
              _text(_emailController, "Email"),
              const SizedBox(height: 12),
              _text(_passwordController, "Password", obscureText: true),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("SIMPAN"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _text(
    TextEditingController c,
    String label, {
    bool number = false,
    bool multi = false,
    int? length,
    bool obscureText = false, // Added for password field
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        maxLines: multi ? null : 1,
        maxLength: length,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        obscureText: obscureText, // Added to handle password visibility
        inputFormatters: number
            ? [FilteringTextInputFormatter.digitsOnly]
            : null,
        decoration: _inputDecoration.copyWith(labelText: label),
        validator: (v) => v == null || v.isEmpty ? "Wajib diisi" : null,
      ),
    );
  }

  Widget _dateField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _tanggalLahirController,
        readOnly: true,
        decoration: _inputDecoration.copyWith(
          labelText: "Tanggal Lahir",
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        onTap: () => _selectDate(context),
        validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: _inputDecoration.copyWith(labelText: label),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
        validator: (v) => v == null ? "Wajib dipilih" : null,
      ),
    );
  }
}
