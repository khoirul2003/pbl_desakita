import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/models/iuran_model.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Edit Iuran: ${widget.iuran.namaIuran}")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Detail Iuran",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(labelText: "Nama Iuran"),
                validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _deskripsiController,
                decoration: const InputDecoration(labelText: "Deskripsi"),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _jumlahController,
                decoration: const InputDecoration(
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

              Text(
                "Target & Tipe",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _tipeIuranValue,
                decoration: const InputDecoration(labelText: "Tipe Penagihan"),
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
                onPressed: _isLoading ? null : _submitUpdateIuran,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text("SIMPAN PERUBAHAN"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
