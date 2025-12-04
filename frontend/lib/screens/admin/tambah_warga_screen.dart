import 'package:flutter/material.dart';
import 'package:frontend/models/user_model.dart';
import 'package:frontend/services/api_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart'; // Untuk FilteringTextInputFormatter


// --- DEFINISI WARNA PROSCAN ---
const Color _primaryColor = Color(0xFF0E2F60); // Biru Tua
const Color _backgroundColor = Color(0xFFF5F5F5); // Abu-abu muda untuk Scaffold
const Color _accentColor = Color(0xFF3C486B); // Aksen Biru/Abu


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
  final _noHpController = TextEditingController(); // Ditambahkan: No HP

  // State untuk Dropdown
  String? _jenisKelaminValue;
  String? _statusDalamKeluargaValue;
  DateTime? _selectedDate;
  bool _isLoading = false;

  // Custom Input Decoration (Gaya ProScan)
  final InputDecoration _inputDecoration = InputDecoration(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12), // Sudut membulat
      borderSide: BorderSide.none, // Menghilangkan border default
    ),
    filled: true,
    fillColor: Colors.white, // Latar belakang input field putih
    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    hintStyle: const TextStyle(color: Colors.grey),
    labelStyle: const TextStyle(color: _accentColor),
  );


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
    _noHpController.dispose();
    super.dispose();
  }

  // Fungsi untuk menampilkan Date Picker
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
        // Memastikan format YYYY-MM-DD
        _tanggalLahirController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _submitTambahWarga() async {
    if (!_formKey.currentState!.validate()) {
      return; 
    }

    setState(() {
      _isLoading = true;
    });

    final apiService = context.read<ApiService>();
    
    // PERHATIAN: Pastikan data yang dikirim sesuai dengan validasi Laravel
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
      "keluarga_id": int.tryParse(_keluargaIdController.text),
      "status_dalam_keluarga": _statusDalamKeluargaValue,
      "kewarganegaraan": "WNI", 
      "no_hp": _noHpController.text.isNotEmpty ? _noHpController.text : null, // Tambahan No HP
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
        // Server mengembalikan respons 200/201 tapi data null, ini jarang terjadi
        throw Exception("Respons berhasil, tetapi data warga tidak diterima.");
      }
    } catch (e) {
      // Ini menangkap error 422 dari Dio/ApiService
      String errorMessage = "Terjadi kesalahan: $e";
      if (e.toString().contains('422')) {
        errorMessage = "Gagal validasi data. Pastikan ID Keluarga (KK) dan format lainnya benar.";
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
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
      backgroundColor: _backgroundColor,
      body: Column(
        children: [
          _buildCustomHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Bagian Data Kependudukan ---
                    _buildSectionTitle(context, "Data Kependudukan (Sesuai KTP)"),
                    
                    TextFormField(
                      controller: _namaController,
                      decoration: _inputDecoration.copyWith(labelText: "Nama Lengkap"),
                      validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nikController,
                      decoration: _inputDecoration.copyWith(labelText: "NIK (16 Digit)"),
                      keyboardType: TextInputType.number,
                      // Memastikan hanya angka yang diizinkan untuk NIK
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) => v!.length != 16 ? "NIK harus 16 digit" : null,
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
                              labelText: "Tanggal Lahir (YYYY-MM-DD)",
                              suffixIcon: const Icon(Icons.calendar_today, color: _primaryColor),
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
                      decoration: _inputDecoration.copyWith(labelText: "Jenis Kelamin"),
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
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _noHpController,
                      decoration: _inputDecoration.copyWith(labelText: "No. HP (Opsional)"),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _alamatKtpController,
                      decoration: _inputDecoration.copyWith(labelText: "Alamat KTP"),
                      maxLines: null, 
                      validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
                    ),
                    
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
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                      decoration: _inputDecoration.copyWith(labelText: "ID Keluarga (KK)"),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _statusDalamKeluargaValue,
                      decoration: _inputDecoration.copyWith(labelText: "Status Dalam Keluarga"),
                      items: const [
                        // OPSI BARU: KEPALA KELUARGA
                        DropdownMenuItem(value: "KEPALA_KELUARGA", child: Text("Kepala Keluarga")),
                        // OPSI LAMA
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              "SIMPAN WARGA",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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