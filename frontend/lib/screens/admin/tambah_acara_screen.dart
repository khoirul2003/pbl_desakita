import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:frontend/services/api_service.dart';
import 'package:flutter/services.dart'; // Untuk FilteringTextInputFormatter

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

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: initialTime,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tambah Acara Baru")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Detail Acara",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(labelText: "Nama Acara"),
                validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _deskripsiController,
                decoration: const InputDecoration(
                  labelText: "Deskripsi Lengkap",
                ),
                maxLines: 4,
                validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lokasiController,
                decoration: const InputDecoration(labelText: "Lokasi"),
                validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
              ),
              const SizedBox(height: 24),

              Text(
                "Pendanaan dan Jadwal",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),

              // Field Biaya
              TextFormField(
                controller: _biayaController,
                decoration: const InputDecoration(
                  labelText: "Total Biaya (Rp)",
                  prefixText: 'Rp ',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  final amount = double.tryParse(v ?? '0');
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
                "Mulai:",
                _tanggalMulai,
                _waktuMulai,
                () => _selectDateTime(context, true),
              ),
              const SizedBox(height: 16),

              // Tanggal & Waktu Selesai
              _buildDateTimeRow(
                context,
                "Selesai:",
                _tanggalSelesai,
                _waktuSelesai,
                () => _selectDateTime(context, false),
              ),

              const SizedBox(height: 24),

              Text(
                "Lingkup Acara",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _rtController,
                      decoration: const InputDecoration(
                        labelText: "RT (Opsional)",
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 3,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _rwController,
                      decoration: const InputDecoration(
                        labelText: "RW (Opsional)",
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitAcara,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text("SIMPAN ACARA"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget Helper untuk menampilkan tanggal dan waktu
  Widget _buildDateTimeRow(
    BuildContext context,
    String label,
    DateTime? date,
    TimeOfDay? time,
    VoidCallback onTap,
  ) {
    final String dateText = date == null
        ? 'Pilih Tanggal'
        : DateFormat('yyyy-MM-dd').format(date);
    final String timeText = time == null ? 'Pilih Waktu' : time.format(context);

    return InkWell(
      onTap: _isLoading ? null : onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(dateText, style: const TextStyle(fontSize: 16)),
            Text(timeText, style: const TextStyle(fontSize: 16)),
            const Icon(Icons.calendar_today, size: 20),
          ],
        ),
      ),
    );
  }
}
