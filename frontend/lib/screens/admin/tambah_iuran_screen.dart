import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:frontend/services/api_service.dart';
import 'package:intl/intl.dart';

const Color _primaryColor = Color(0xFF0E2F60);
const Color _accentColor = Color(0xFF3C486B);
const Color _backgroundColor = Color(0xFFF5F5F5);

class TambahIuranScreen extends StatefulWidget {
  const TambahIuranScreen({super.key});

  @override
  State<TambahIuranScreen> createState() => _TambahIuranScreenState();
}

class _TambahIuranScreenState extends State<TambahIuranScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _jumlahController = TextEditingController();
  final _rtController = TextEditingController();
  final _rwController = TextEditingController();

  final _tanggalJatuhTempoController = TextEditingController();
  DateTime? _selectedDate;

  String? _tipeIuranValue;
  bool _isLoading = false;

  final InputDecoration _inputDecoration = InputDecoration(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    labelStyle: const TextStyle(color: _accentColor),
    prefixStyle: const TextStyle(
      fontWeight: FontWeight.bold,
      color: _primaryColor,
    ),
  );

  @override
  void dispose() {
    _namaController.dispose();
    _deskripsiController.dispose();
    _jumlahController.dispose();
    _rtController.dispose();
    _rwController.dispose();
    _tanggalJatuhTempoController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;

        _tanggalJatuhTempoController.text = DateFormat(
          'yyyy-MM-dd',
        ).format(picked);
      });
    }
  }

  Future<void> _submitIuran() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final apiService = context.read<ApiService>();
    final Map<String, dynamic> data = {
      'nama_iuran': _namaController.text,
      'deskripsi': _deskripsiController.text,
      'jumlah': double.tryParse(_jumlahController.text),
      'tipe': _tipeIuranValue,
      'rt': _rtController.text.isNotEmpty ? _rtController.text : null,
      'rw': _rwController.text.isNotEmpty ? _rwController.text : null,

      'tanggal_jatuh_tempo': _tanggalJatuhTempoController.text,
    };

    try {
      final success = await apiService.createIuran(data);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Jenis iuran berhasil ditambahkan!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
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
            "Tambah Jenis Iuran Baru",
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

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0, left: 4),
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
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 24.0,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSectionTitle(context, "Detail Iuran"),

                    TextFormField(
                      controller: _namaController,
                      decoration: _inputDecoration.copyWith(
                        labelText: "Nama Iuran (cth: Sampah, Keamanan)",
                      ),
                      validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _deskripsiController,
                      decoration: _inputDecoration.copyWith(
                        labelText: "Deskripsi",
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _jumlahController,
                      decoration: _inputDecoration.copyWith(
                        labelText: "Jumlah (Nominal)",
                        prefixText: "Rp ",
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) {
                        final amount = double.tryParse(v ?? '');
                        if (amount == null || amount <= 0) {
                          return "Masukkan jumlah yang valid";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    _buildSectionTitle(context, "Target & Jadwal"),

                    TextFormField(
                      controller: _tanggalJatuhTempoController,
                      decoration: _inputDecoration.copyWith(
                        labelText: "Tanggal Jatuh Tempo Pertama",
                        suffixIcon: IconButton(
                          icon: const Icon(
                            Icons.calendar_today,
                            color: _primaryColor,
                          ),
                          onPressed: () => _selectDate(context),
                        ),
                      ),
                      readOnly: true,
                      onTap: () => _selectDate(context),
                      validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: _tipeIuranValue,
                      decoration: _inputDecoration.copyWith(
                        labelText: "Tipe Penagihan",
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: "PER_WARGA",
                          child: Text("Per Warga (Individu)"),
                        ),
                        DropdownMenuItem(
                          value: "PER_KELUARGA",
                          child: Text("Per Keluarga (KK)"),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _tipeIuranValue = value),
                      validator: (v) => v == null ? "Wajib dipilih" : null,
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _rtController,
                            decoration: _inputDecoration.copyWith(
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
                            decoration: _inputDecoration.copyWith(
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
                      onPressed: _isLoading ? null : _submitIuran,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text("SIMPAN JENIS IURAN"),
                    ),
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
