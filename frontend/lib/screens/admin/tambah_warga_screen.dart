import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:frontend/models/user_model.dart';
import 'package:frontend/services/api_service.dart';
import 'package:provider/provider.dart';






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
  final _keluargaIdController =
      TextEditingController(); 

  
  String? _jenisKelaminValue;
  String? _statusDalamKeluargaValue;
  DateTime? _selectedDate;
  bool _isLoading = false;

  
  Future<void> _selectDate(BuildContext context) async {
    // Menggunakan tema kustom untuk Date Picker
    final ThemeData datePickerTheme = ThemeData.light().copyWith(
      colorScheme: const ColorScheme.light(
        primary: _primaryColor, 
        onPrimary: Colors.white,
        onSurface: Colors.black,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: _primaryColor),
      ),
    );

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(data: datePickerTheme, child: child!),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _tanggalLahirController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
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
      "kewarganegaraan": "WNI", 
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Gagal menambah warga. Periksa kembali data."),
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
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
  
  // --- WIDGET: SECTION TITLE (Padding disesuaikan) ---
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
                controller: _keluargaIdController,
                decoration: const InputDecoration(
                  labelText: "ID Keluarga (KK)",
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
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