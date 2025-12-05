import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:frontend/models/user_model.dart';
import 'package:frontend/services/api_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart'; // <-- Diperlukan untuk Input Formatters
import 'package:intl/intl.dart';

class TambahWargaScreen extends StatefulWidget {
  const TambahWargaScreen({super.key});

  @override
  State<TambahWargaScreen> createState() => _TambahWargaScreenState();
}

class _TambahWargaScreenState extends State<TambahWargaScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _namaController = TextEditingController();
  final _nikController = TextEditingController();
  final _tempatLahirController = TextEditingController();
  final _tanggalLahirController = TextEditingController();
  final _agamaController = TextEditingController();
  final _statusPerkawinanController = TextEditingController();
  final _pekerjaanController = TextEditingController();
  final _rtController = TextEditingController();
  final _rwController = TextEditingController();
  final _alamatKtpController = TextEditingController();
  final _keluargaIdController = TextEditingController();
  final _noHpController = TextEditingController(); // <-- CONTROLLER BARU: No HP

  // State untuk Dropdown
  String? _jenisKelaminValue;
  String? _statusDalamKeluargaValue;
  DateTime? _selectedDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _namaController.dispose();
    _nikController.dispose();
    _tempatLahirController.dispose();
    _tanggalLahirController.dispose();
    _agamaController.dispose();
    _statusPerkawinanController.dispose();
    _pekerjaanController.dispose();
    _rtController.dispose();
    _rwController.dispose();
    _alamatKtpController.dispose();
    _keluargaIdController.dispose();
    _noHpController.dispose(); // <-- DISPOSE: No HP
    super.dispose();
  }

  // Fungsi untuk menampilkan Date Picker
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
        // Format tanggal YYYY-MM-DD
        _tanggalLahirController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _submitTambahWarga() async {
    if (!_formKey.currentState!.validate()) {
      return; // Validasi gagal
    }

    setState(() {
      _isLoading = true;
    });

    final apiService = context.read<ApiService>();

    // Kumpulkan data ke dalam Map
    final Map<String, dynamic> data = {
      "nama_lengkap": _namaController.text,
      "nik": _nikController.text,
      "tempat_lahir": _tempatLahirController.text,
      "tanggal_lahir": _tanggalLahirController.text,
      "jenis_kelamin": _jenisKelaminValue,
      "agama": _agamaController.text,
      "status_perkawinan": _statusPerkawinanController.text,
      "pekerjaan": _pekerjaanController.text,
      "rt": _rtController.text,
      "rw": _rwController.text,
      "alamat_ktp": _alamatKtpController.text,
      // Konversi ke int
      "keluarga_id": int.tryParse(_keluargaIdController.text),
      "status_dalam_keluarga": _statusDalamKeluargaValue,
      "no_hp": _noHpController.text.isNotEmpty
          ? _noHpController.text
          : null, // <-- KIRIM NO HP
      "kewarganegaraan": "WNI", // Default
    };

    try {
      final Warga? newWarga = await apiService.createManajemenWarga(data);

      if (newWarga != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Berhasil menambah ${newWarga.namaLengkap}."),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        // Logika untuk menangkap 422 error dan menampilkan pesan yang lebih baik
        throw Exception("Gagal menambah warga. Periksa data NIK/ID Keluarga.");
      }
    } catch (e) {
      // Menangkap DioException dan menampilkan pesan yang lebih detail
      String errorMessage = "Terjadi kesalahan";
      if (e is DioException && e.response != null) {
        if (e.response!.statusCode == 422) {
          // Gagal validasi Laravel: Ambil pesan error pertama
          final errors = e.response!.data['errors'] as Map<String, dynamic>;
          // Coba ambil pesan error yang paling relevan (misal: NIK sudah ada)
          errorMessage = "Validasi Gagal: ${errors.values.first.first}";
        } else {
          errorMessage =
              "Error Server ${e.response!.statusCode}: Cek koneksi atau token.";
        }
      } else {
        errorMessage = e.toString();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal: $errorMessage"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tambah Warga Baru")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Data Kependudukan (Sesuai KTP)",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(labelText: "Nama Lengkap"),
                validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nikController,
                decoration: const InputDecoration(labelText: "NIK (16 Digit)"),
                keyboardType: TextInputType.number,
                validator: (v) => v!.length != 16 ? "NIK harus 16 digit" : null,
                // --- FORMATTER NIK ---
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(16),
                ],
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
                decoration: const InputDecoration(labelText: "Jenis Kelamin"),
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
              const SizedBox(height: 16),
              // --- FIELD BARU: NO HP ---
              TextFormField(
                controller: _noHpController,
                decoration: const InputDecoration(
                  labelText: "No. HP (Opsional)",
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _alamatKtpController,
                decoration: const InputDecoration(labelText: "Alamat KTP"),
                validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
              ),
              const SizedBox(height: 24),
              Text(
                "Data Domisili & Keluarga",
                style: Theme.of(context).textTheme.titleLarge,
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
                      // --- FORMATTER RT ---
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
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
                      // --- FORMATTER RW ---
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _keluargaIdController,
                decoration: const InputDecoration(
                  labelText: "ID Keluarga (KK)",
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
                // --- FORMATTER KK ID ---
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _statusDalamKeluargaValue,
                decoration: const InputDecoration(
                  labelText: "Status Dalam Keluarga",
                ),
                items: const [
                  DropdownMenuItem(value: "ISTRI", child: Text("Istri")),
                  DropdownMenuItem(value: "ANAK", child: Text("Anak")),
                  DropdownMenuItem(value: "LAINNYA", child: Text("Lainnya")),
                ],
                onChanged: (value) {
                  setState(() {
                    _statusDalamKeluargaValue = value;
                  });
                },
                validator: (v) => v == null ? "Wajib dipilih" : null,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitTambahWarga,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text("SIMPAN WARGA"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
