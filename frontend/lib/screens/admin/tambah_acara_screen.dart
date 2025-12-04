import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:frontend/services/api_service.dart';
import 'package:flutter/services.dart'; // Untuk FilteringTextInputFormatter

// --- DEFINISI WARNA PROSCAN ---
const Color _primaryColor = Color(0xFF0E2F60); // Biru Tua
const Color _backgroundColor = Color(0xFFF5F5F5); // Abu-abu muda untuk Scaffold
const Color _accentColor = Color(0xFF3C486B); // Aksen Biru/Abu

class TambahAcaraScreen extends StatefulWidget {
  const TambahAcaraScreen({super.key});

  @override
  State<TambahAcaraScreen> createState() => _TambahAcaraScreenState();
}

class _TambahAcaraScreenState extends State<TambahAcaraScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _lokasiController = TextEditingController();
  final _rtController = TextEditingController();
  final _rwController = TextEditingController();
  final _biayaController = TextEditingController(
    text: '0',
  ); // Controller Biaya (default 0)

  DateTime? _tanggalMulai;
  TimeOfDay? _waktuMulai;
  DateTime? _tanggalSelesai;
  TimeOfDay? _waktuSelesai;

  bool _isLoading = false;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  // Custom Input Decoration (Sama seperti Edit Warga)
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
    _deskripsiController.dispose();
    _lokasiController.dispose();
    _rtController.dispose();
    _rwController.dispose();
    _biayaController.dispose();
    super.dispose();
  }

  // Helper untuk menggabungkan DateTime dan TimeOfDay
  DateTime _combineDateTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  // Helper untuk memilih tanggal dan waktu
  Future<void> _selectDateTime(BuildContext context, bool isMulai) async {
    DateTime initialDate = DateTime.now();
    TimeOfDay initialTime = TimeOfDay.now();

    if (isMulai) {
      if (_tanggalMulai != null) initialDate = _tanggalMulai!;
      if (_waktuMulai != null) initialTime = _waktuMulai!;
    } else {
      if (_tanggalSelesai != null) initialDate = _tanggalSelesai!;
      if (_waktuSelesai != null) initialTime = _waktuSelesai!;
    }
    
    // Menggunakan tema kustom untuk Date Picker
    final ThemeData datePickerTheme = ThemeData.light().copyWith(
      colorScheme: const ColorScheme.light(
        primary: _primaryColor, 
        onPrimary: Colors.white,
        surface: Colors.white,
        onSurface: Colors.black,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: _primaryColor),
      ),
    );

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
      builder: (context, child) => Theme(data: datePickerTheme, child: child!),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: initialTime,
        builder: (context, child) => Theme(data: datePickerTheme, child: child!),
      );

      if (pickedTime != null) {
        setState(() {
          if (isMulai) {
            _tanggalMulai = pickedDate;
            _waktuMulai = pickedTime;
          } else {
            _tanggalSelesai = pickedDate;
            _waktuSelesai = pickedTime;
          }
        });
      }
    }
  }

  Future<void> _submitAcara() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_tanggalMulai == null ||
        _waktuMulai == null ||
        _tanggalSelesai == null ||
        _waktuSelesai == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Tanggal dan waktu mulai/selesai wajib diisi."),
        ),
      );
      return;
    }

    final tglMulai = _combineDateTime(_tanggalMulai!, _waktuMulai!);
    final tglSelesai = _combineDateTime(_tanggalSelesai!, _waktuSelesai!);

    if (tglSelesai.isBefore(tglMulai)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Tanggal Selesai tidak boleh mendahului Tanggal Mulai.",
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Ambil Biaya
    final double? totalBiaya = double.tryParse(_biayaController.text);
    if (totalBiaya == null || totalBiaya < 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Total Biaya harus berupa angka positif."),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final apiService = context.read<ApiService>();
    final Map<String, dynamic> data = {
      'nama_acara': _namaController.text,
      'deskripsi': _deskripsiController.text,
      'tanggal_mulai': tglMulai.toIso8601String(),
      'tanggal_selesai': tglSelesai.toIso8601String(),
      'lokasi': _lokasiController.text,
      'rt': _rtController.text.isNotEmpty ? _rtController.text : null,
      'rw': _rwController.text.isNotEmpty ? _rwController.text : null,
      'total_biaya': totalBiaya, // <-- Kirim total biaya
    };

    try {
      final success = await apiService.createAcara(data);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Acara berhasil ditambahkan!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Pop dengan hasil true untuk refresh
      } else {
        throw Exception("Gagal menyimpan data ke server.");
      }
    } catch (e) {
      if (mounted) {
        // Tampilkan pesan error yang lebih informatif jika dari server
        String errorMessage = e.toString().contains('403')
            ? 'Akses Ditolak. Pastikan RT/RW sesuai otoritas Anda.'
            : 'Error: ${e.toString()}';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
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
            "Tambah Acara Baru",
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
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
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


  // Widget Helper untuk menampilkan tanggal dan waktu (Diperbarui dengan gaya ProScan)
  Widget _buildDateTimeRow(
    BuildContext context,
    String label,
    DateTime? date,
    TimeOfDay? time,
    VoidCallback onTap,
  ) {
    final String dateText = date == null
        ? 'Pilih Tanggal'
        : DateFormat('dd MMM yyyy').format(date);
    final String timeText = time == null ? 'Pilih Waktu' : time.format(context);

    return InkWell(
      onTap: _isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.transparent), // Border transparan agar sama dengan TextFormField
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: _accentColor),
                ),
                const SizedBox(height: 4),
                Text(
                  "$dateText | $timeText", 
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ],
            ),
            const Icon(Icons.calendar_month_rounded, size: 24, color: _primaryColor),
          ],
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
                    // --- Bagian Detail Acara ---
                    _buildSectionTitle(context, "Detail Acara"),
                    
                    TextFormField(
                      controller: _namaController,
                      decoration: _inputDecoration.copyWith(labelText: "Nama Acara"),
                      validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _deskripsiController,
                      decoration: _inputDecoration.copyWith(
                        labelText: "Deskripsi Lengkap",
                      ),
                      maxLines: 4,
                      validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _lokasiController,
                      decoration: _inputDecoration.copyWith(labelText: "Lokasi"),
                      validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
                    ),
                    const SizedBox(height: 24),

                    // --- Pendanaan dan Jadwal ---
                    _buildSectionTitle(context, "Pendanaan dan Jadwal"),

                    // Field Biaya
                    TextFormField(
                      controller: _biayaController,
                      decoration: _inputDecoration.copyWith(
                        
                        prefixText: 'Rp ',
                        prefixStyle: const TextStyle(fontWeight: FontWeight.bold, color: _primaryColor),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) {
                        final amount = double.tryParse(v ?? '');
                        if (amount == null || amount < 0) {
                          return "Biaya harus angka positif.";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Tanggal & Waktu Mulai
                    _buildDateTimeRow(
                      context,
                      "Tanggal & Waktu Mulai",
                      _tanggalMulai,
                      _waktuMulai,
                      () => _selectDateTime(context, true),
                    ),
                    const SizedBox(height: 16),

                    // Tanggal & Waktu Selesai
                    _buildDateTimeRow(
                      context,
                      "Tanggal & Waktu Selesai",
                      _tanggalSelesai,
                      _waktuSelesai,
                      () => _selectDateTime(context, false),
                    ),

                    const SizedBox(height: 24),

                    // --- Lingkup Acara ---
                    _buildSectionTitle(context, "Lingkup Acara"),
                    
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _rtController,
                            decoration: _inputDecoration.copyWith(
                              labelText: "RT (Opsional)",
                              counterText: "",
                            ),
                            keyboardType: TextInputType.number,
                            maxLength: 3,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _rwController,
                            decoration: _inputDecoration.copyWith(
                              labelText: "RW (Opsional)",
                              counterText: "",
                            ),
                            keyboardType: TextInputType.number,
                            maxLength: 3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    // --- Tombol SIMPAN ---
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitAcara,
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
                              "SIMPAN ACARA",
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