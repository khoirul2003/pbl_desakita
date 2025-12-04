import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/models/iuran_model.dart';

// --- DEFINISI WARNA PROSCAN ---
const Color _primaryColor = Color(0xFF0E2F60); // Biru Tua
const Color _backgroundColor = Color(0xFFF5F5F5); // Abu-abu muda untuk Scaffold
const Color _accentColor = Color(0xFF3C486B); // Aksen Biru/Abu

class EditIuranScreen extends StatefulWidget {
  final Iuran iuran;
  const EditIuranScreen({super.key, required this.iuran});

  @override
  State<EditIuranScreen> createState() => _EditIuranScreenState();
}

class _EditIuranScreenState extends State<EditIuranScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _namaController;
  late TextEditingController _deskripsiController;
  late TextEditingController _jumlahController;
  late TextEditingController _rtController;
  late TextEditingController _rwController;

  String? _tipeIuranValue;
  bool _isLoading = false;

  // Custom Input Decoration
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
  void initState() {
    super.initState();
    final iuran = widget.iuran;
    _namaController = TextEditingController(text: iuran.namaIuran);
    _deskripsiController = TextEditingController(text: iuran.deskripsi);
    _jumlahController = TextEditingController(
      text: iuran.jumlah.toStringAsFixed(0),
    );
    _rtController = TextEditingController(text: iuran.rt);
    _rwController = TextEditingController(text: iuran.rw);
    _tipeIuranValue = iuran.tipe;
  }

  @override
  void dispose() {
    _namaController.dispose();
    _deskripsiController.dispose();
    _jumlahController.dispose();
    _rtController.dispose();
    _rwController.dispose();
    super.dispose();
  }

  Future<void> _submitUpdateIuran() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final apiService = context.read<ApiService>();
    final Map<String, dynamic> data = {
      // Hanya kirim data yang bisa diubah
      'nama_iuran': _namaController.text,
      'deskripsi': _deskripsiController.text,
      'jumlah': double.tryParse(_jumlahController.text),
      'tipe': _tipeIuranValue,
      'rt': _rtController.text.isNotEmpty ? _rtController.text : null,
      'rw': _rwController.text.isNotEmpty ? _rwController.text : null,
    };

    try {
      final success = await apiService.updateIuran(widget.iuran.id, data);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Jenis iuran berhasil diperbarui!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Pop dengan hasil true untuk refresh
      } else {
        throw Exception("Gagal menyimpan perubahan ke server.");
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
          Expanded(
            child: Text(
              "Edit Iuran: ${widget.iuran.namaIuran}",
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
                    // --- Bagian Detail Iuran ---
                    _buildSectionTitle(context, "Detail Iuran"),
                    
                    TextFormField(
                      controller: _namaController,
                      decoration: _inputDecoration.copyWith(labelText: "Nama Iuran"),
                      validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _deskripsiController,
                      decoration: _inputDecoration.copyWith(labelText: "Deskripsi (Opsional)"),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _jumlahController,
                      decoration: _inputDecoration.copyWith(
                        labelText: "Jumlah (Nominal)",
                        prefixText: "Rp ",
                        prefixStyle: const TextStyle(fontWeight: FontWeight.bold, color: _primaryColor),
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
                    
                    // --- Bagian Target & Tipe ---
                    _buildSectionTitle(context, "Target & Tipe"),
                    
                    DropdownButtonFormField<String>(
                      value: _tipeIuranValue,
                      decoration: _inputDecoration.copyWith(labelText: "Tipe Penagihan"),
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
                      onChanged: (value) => setState(() => _tipeIuranValue = value),
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
                    // --- Tombol SIMPAN ---
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitUpdateIuran,
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