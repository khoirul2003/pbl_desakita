import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart'; 
import 'package:dio/dio.dart'; // Import Dio untuk menangkap DioException

// --- DEFINISI WARNA PROSCAN ---
const Color _primaryColor = Color(0xFF0E2F60); 
const Color _backgroundColor = Color(0xFFF5F5F5); 
const Color _accentColor = Color(0xFF3C486B); 

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
  final _alamatKtpController = TextEditingController();
  final _keluargaIdController = TextEditingController();
  final _noHpController = TextEditingController(); 

  // State untuk Dropdown
  String? _jenisKelaminValue;
  String? _statusDalamKeluargaValue;
  String? _roleValue = 'warga'; // Default Role
  DateTime? _selectedDate;
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
      "no_hp": _noHpController.text.isNotEmpty
          ? _noHpController.text
          : null,
      "role": _roleValue, // Field Role yang baru
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

        Navigator.of(context).pop(true);
      } else {
        throw Exception("Respons berhasil, tetapi data warga tidak diterima.");
      }
    } catch (e) {
      // <<< PERBAIKAN: DEBUGGING ERROR 500/400 DARI BACKEND >>>
      String errorMessage = "Terjadi kesalahan server yang tidak diketahui.";
      
      if (e is DioException) {
        if (e.response?.statusCode == 500) {
           errorMessage = "Gagal internal server (500). Cek log Laravel!";
        } else if (e.response?.statusCode == 422) {
           // Error Validasi Laravel
           errorMessage = "Gagal validasi data. Pastikan semua field wajib diisi dan benar.";
           if (e.response?.data is Map && e.response!.data['message'] != null) {
              errorMessage = "Validasi gagal: ${e.response!.data['message']}";
              // Jika Anda ingin menampilkan error detail, Anda perlu parsing e.response!.data['errors']
           }
        } else {
           errorMessage = "Error API: ${e.message} (Status: ${e.response?.statusCode})";
        }
      } else {
        errorMessage = e.toString();
      }

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

  // --- WIDGET: CUSTOM HEADER PROSCAN ---
  Widget _buildCustomHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      decoration: const BoxDecoration(
        color: _primaryColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          const Text(
            "Tambah Warga Baru",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET: SECTION TITLE ---
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: _primaryColor,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
    );
  }

  // ================= UI =================
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

                    // ... Field-field data kependudukan
                    TextFormField(controller: _namaController, decoration: _inputDecoration.copyWith(labelText: "Nama Lengkap"), validator: (v) => v!.isEmpty ? "Wajib diisi" : null),
                    const SizedBox(height: 16),
                    TextFormField(controller: _nikController, decoration: _inputDecoration.copyWith(labelText: "NIK (16 Digit)"), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], validator: (v) => v!.length != 16 ? "NIK harus 16 digit" : null),
                    const SizedBox(height: 16),
                    Row(children: [Expanded(child: TextFormField(controller: _tempatLahirController, decoration: _inputDecoration.copyWith(labelText: "Tempat Lahir"), validator: (v) => v!.isEmpty ? "Wajib diisi" : null)), const SizedBox(width: 16), Expanded(child: TextFormField(controller: _tanggalLahirController, decoration: _inputDecoration.copyWith(labelText: "Tanggal Lahir (YYYY-MM-DD)", suffixIcon: const Icon(Icons.calendar_today, color: _primaryColor)), readOnly: true, onTap: () => _selectDate(context), validator: (v) => v!.isEmpty ? "Wajib diisi" : null))]),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(value: _jenisKelaminValue, decoration: _inputDecoration.copyWith(labelText: "Jenis Kelamin"), items: const [DropdownMenuItem(value: "L", child: Text("Laki-laki")), DropdownMenuItem(value: "P", child: Text("Perempuan"))], onChanged: (value) {setState(() {_jenisKelaminValue = value;});}, validator: (v) => v == null ? "Wajib dipilih" : null),
                    const SizedBox(height: 16),
                    TextFormField(controller: _agamaController, decoration: _inputDecoration.copyWith(labelText: "Agama"), validator: (v) => v!.isEmpty ? "Wajib diisi" : null),
                    const SizedBox(height: 16),
                    TextFormField(controller: _statusPerkawinanController, decoration: _inputDecoration.copyWith(labelText: "Status Perkawinan"), validator: (v) => v!.isEmpty ? "Wajib diisi" : null),
                    const SizedBox(height: 16),
                    TextFormField(controller: _pekerjaanController, decoration: _inputDecoration.copyWith(labelText: "Pekerjaan"), validator: (v) => v!.isEmpty ? "Wajib diisi" : null),
                    const SizedBox(height: 16),
                    TextFormField(controller: _noHpController, decoration: _inputDecoration.copyWith(labelText: "No. HP (Opsional)"), keyboardType: TextInputType.phone),
                    const SizedBox(height: 16),
                    TextFormField(controller: _alamatKtpController, decoration: _inputDecoration.copyWith(labelText: "Alamat KTP"), maxLines: null, validator: (v) => v!.isEmpty ? "Wajib diisi" : null),
                    
                    // --- Data Domisili & Keluarga ---
                    const SizedBox(height: 24),
                    _buildSectionTitle(context, "Data Domisili & Keluarga"),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _rtController,
                            decoration: _inputDecoration.copyWith(
                              labelText: "RT (mis: 001)",
                              counterText: "",
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            maxLength: 3,
                            validator: (v) =>
                                v!.length != 3 ? "Format 3 digit (001)" : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _rwController,
                            decoration: _inputDecoration.copyWith(
                              labelText: "RW (mis: 001)",
                              counterText: "",
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            maxLength: 3,
                            validator: (v) =>
                                v!.length != 3 ? "Format 3 digit (001)" : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _keluargaIdController,
                      decoration: _inputDecoration.copyWith(
                        labelText: "ID Keluarga (KK)",
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _statusDalamKeluargaValue,
                      decoration: _inputDecoration.copyWith(
                        labelText: "Status Dalam Keluarga",
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: "KEPALA_KELUARGA",
                          child: Text("Kepala Keluarga"),
                        ),
                        DropdownMenuItem(value: "ISTRI", child: Text("Istri")),
                        DropdownMenuItem(value: "ANAK", child: Text("Anak")),
                        DropdownMenuItem(
                          value: "LAINNYA",
                          child: Text("Lainnya"),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _statusDalamKeluargaValue = value;
                        });
                      },
                      validator: (v) => v == null ? "Wajib dipilih" : null,
                    ),
                    
                    // DROPDOWN UNTUK MEMILIH ROLE
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _roleValue,
                      decoration: _inputDecoration.copyWith(
                        labelText: "Role/Jabatan (Default: Warga)",
                      ),
                      items: const [
                        DropdownMenuItem(value: "warga", child: Text("Warga")),
                        DropdownMenuItem(value: "rt", child: Text("Ketua RT")),
                        DropdownMenuItem(value: "rw", child: Text("Ketua RW")),
                        DropdownMenuItem(value: "admin", child: Text("Admin")),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _roleValue = value;
                        });
                      },
                      validator: (v) => v == null ? "Wajib dipilih" : null,
                    ),

                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitTambahWarga,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
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

  // ================= HELPER =================
  Widget _text(
    TextEditingController c,
    String label, {
    bool number = false,
    bool multi = false,
    int? length,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        maxLines: multi ? null : 1,
        maxLength: length,
        keyboardType: number ? TextInputType.number : TextInputType.text,
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