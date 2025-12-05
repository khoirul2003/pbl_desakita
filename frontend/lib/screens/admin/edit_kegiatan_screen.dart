import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/models/kegiatan_model.dart';
import 'package:flutter/services.dart';

// --- DEFINISI WARNA PROSCAN (Disesuaikan dengan Edit Acara Screen) ---
const Color _primaryColor = Color(0xFF0E2F60); // Biru Tua
const Color _backgroundColor = Color(0xFFF5F5F5); // Abu-abu muda untuk Scaffold
const Color _accentColor = Color(0xFF3C486B); // Aksen Biru/Abu

class EditKegiatanScreen extends StatefulWidget {
  final Kegiatan kegiatan;
  const EditKegiatanScreen({super.key, required this.kegiatan});

  @override
  State<EditKegiatanScreen> createState() => _EditKegiatanScreenState();
}

class _EditKegiatanScreenState extends State<EditKegiatanScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _namaController;
  late TextEditingController _deskripsiController;
  late TextEditingController _lokasiController;
  late TextEditingController _rtController;
  late TextEditingController _rwController;

  DateTime? _tanggalMulai;
  TimeOfDay? _waktuMulai;
  DateTime? _tanggalSelesai;
  TimeOfDay? _waktuSelesai;

  bool _isLoading = false;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  final DateFormat _timeFormat = DateFormat('HH:mm');

  // Custom Input Decoration (Sesuai Edit Acara)
  final InputDecoration _inputDecoration = InputDecoration(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    hintStyle: const TextStyle(color: Colors.grey),
    labelStyle: const TextStyle(color: _accentColor),
  );

  @override
  void initState() {
    super.initState();
    final kegiatan = widget.kegiatan;
    _namaController = TextEditingController(text: kegiatan.namaKegiatan);
    _deskripsiController = TextEditingController(text: kegiatan.deskripsi);
    _lokasiController = TextEditingController(text: kegiatan.lokasi);
    _rtController = TextEditingController(text: kegiatan.rt);
    _rwController = TextEditingController(text: kegiatan.rw);

    // Inisialisasi Tanggal dan Waktu
    _tanggalMulai = kegiatan.tanggalMulai;
    _waktuMulai = TimeOfDay.fromDateTime(kegiatan.tanggalMulai);
    _tanggalSelesai = kegiatan.tanggalSelesai;
    _waktuSelesai = TimeOfDay.fromDateTime(kegiatan.tanggalSelesai);
  }

  @override
  void dispose() {
    _namaController.dispose();
    _deskripsiController.dispose();
    _lokasiController.dispose();
    _rtController.dispose();
    _rwController.dispose();
    super.dispose();
  }

  // Helper untuk menggabungkan DateTime dan TimeOfDay
  DateTime _combineDateTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  // Helper untuk memilih tanggal dan waktu (Ditambahkan custom theme)
  Future<void> _selectDateTime(BuildContext context, bool isMulai) async {
    DateTime initialDate = isMulai ? _tanggalMulai! : _tanggalSelesai!;
    TimeOfDay initialTime = isMulai ? _waktuMulai! : _waktuSelesai!;
    
    // Menggunakan tema kustom untuk Date Picker (Sesuai Edit Acara)
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

  Future<void> _submitUpdateKegiatan() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_tanggalMulai == null ||
        _waktuMulai == null ||
        _tanggalSelesai == null ||
        _waktuSelesai == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tanggal dan waktu wajib diisi.")),
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

    final apiService = context.read<ApiService>();
    final Map<String, dynamic> data = {
      'nama_kegiatan': _namaController.text,
      'deskripsi': _deskripsiController.text,
      'tanggal_mulai': tglMulai.toIso8601String(),
      'tanggal_selesai': tglSelesai.toIso8601String(),
      'lokasi': _lokasiController.text,
      'rt': _rtController.text.isNotEmpty ? _rtController.text : null,
      'rw': _rwController.text.isNotEmpty ? _rwController.text : null,
    };

    try {
      final success = await apiService.updateKegiatan(widget.kegiatan.id, data);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Kegiatan berhasil diperbarui!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Pop dengan hasil true untuk refresh
      } else {
        throw Exception("Gagal menyimpan data ke server.");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
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

  // --- WIDGET: CUSTOM HEADER PROSCAN (Sesuai Edit Acara) ---
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
          Expanded(
            child: Text(
              "Edit Kegiatan: ${widget.kegiatan.namaKegiatan}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // --- WIDGET: SECTION TITLE (Sesuai Edit Acara) ---
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0, bottom: 8.0), 
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

  // Widget Helper untuk menampilkan tanggal dan waktu (Diperbarui dengan gaya Edit Acara)
  Widget _buildDateTimeRow(
    BuildContext context,
    String label,
    DateTime? date,
    TimeOfDay? time,
    VoidCallback onTap,
  ) {
    final String dateText = date == null
        ? 'Pilih Tanggal'
        : DateFormat('dd MMM yyyy').format(date); // Format tanggal disesuaikan
    final String timeText = time == null ? 'Pilih Waktu' : time.format(context);

    return InkWell(
      onTap: _isLoading ? null : onTap,
      child: Container( // Menggunakan Container sebagai ganti InputDecorator
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.transparent), 
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
      backgroundColor: _backgroundColor, // Menggunakan background color baru
      body: Column(
        children: [
          // Header menggantikan AppBar
          _buildCustomHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Bagian Detail Kegiatan ---
                    _buildSectionTitle(context, "Detail Kegiatan"), // Menggunakan helper Title
                    
                    TextFormField(
                      controller: _namaController,
                      decoration: _inputDecoration.copyWith(labelText: "Nama Kegiatan"), // Menggunakan decoration baru
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

                    // --- Jadwal ---
                    _buildSectionTitle(context, "Jadwal Kegiatan"),
                    
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

                    // --- Lingkup Kegiatan ---
                    _buildSectionTitle(context, "Lingkup Kegiatan"),
                    
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _rtController,
                            decoration: _inputDecoration.copyWith(
                              labelText: "RT (Opsional)",
                              counterText: "", // Menghilangkan counter
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
                              counterText: "", // Menghilangkan counter
                            ),
                            keyboardType: TextInputType.number,
                            maxLength: 3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // --- Tombol SIMPAN --- (Sesuai Edit Acara)
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitUpdateKegiatan,
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
                              "SIMPAN PERUBAHAN",
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
