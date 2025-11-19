import 'package:flutter/material.dart';
import 'package:frontend/models/user_model.dart';
import 'package:frontend/services/api_service.dart'; // Menggunakan ApiService tunggal
import 'package:provider/provider.dart';

class EditWargaScreen extends StatefulWidget {
  final Warga warga;
  const EditWargaScreen({super.key, required this.warga});

  @override
  State<EditWargaScreen> createState() => _EditWargaScreenState();
}

class _EditWargaScreenState extends State<EditWargaScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _namaController;
  late TextEditingController _nikController;
  late TextEditingController _tempatLahirController;
  late TextEditingController _tanggalLahirController;
  late TextEditingController _agamaController;
  late TextEditingController _statusPerkawinanController;
  late TextEditingController _pekerjaanController;
  late TextEditingController _rtController;
  late TextEditingController _rwController;
  late TextEditingController _alamatKtpController;
  late TextEditingController _keluargaIdController;
  late TextEditingController _noHpController;

  // State untuk Dropdown
  String? _jenisKelaminValue;
  String? _statusDalamKeluargaValue;
  DateTime? _selectedDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // --- (PENTING) Inisialisasi Controller dengan data warga ---
    final warga = widget.warga;
    _namaController = TextEditingController(text: warga.namaLengkap);
    _nikController = TextEditingController(text: warga.nik);
    _tempatLahirController = TextEditingController(text: warga.tempatLahir);
    _tanggalLahirController = TextEditingController(text: warga.tanggalLahir);
    _agamaController = TextEditingController(text: warga.agama);
    _statusPerkawinanController = TextEditingController(text: warga.statusPerkawinan);
    _pekerjaanController = TextEditingController(text: warga.pekerjaan);
    _rtController = TextEditingController(text: warga.rt);
    _rwController = TextEditingController(text: warga.rw);
    _alamatKtpController = TextEditingController(text: warga.alamatKtp);
    _keluargaIdController = TextEditingController(text: warga.keluargaId?.toString());
    _noHpController = TextEditingController(text: warga.noHp);

    _jenisKelaminValue = warga.jenisKelamin;
    _statusDalamKeluargaValue = warga.statusDalamKeluarga;
    if (warga.tanggalLahir != null && warga.tanggalLahir!.isNotEmpty) {
      _selectedDate = DateTime.tryParse(warga.tanggalLahir!);
    }
  }

  @override
  void dispose() {
    // Pastikan controller di-dispose
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
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _tanggalLahirController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _submitUpdateWarga() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() { _isLoading = true; });

    // --- MENGGANTI: Gunakan ApiService ---
    final apiService = context.read<ApiService>();

    // Kumpulkan data yang di-update
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
      "no_hp": _noHpController.text,
    };

    try {
      // Panggil fungsi update dari ApiService
      final Warga? updatedWarga = await apiService.updateManajemenWarga(widget.warga.id, data);

      if (updatedWarga != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Berhasil memperbarui ${updatedWarga.namaLengkap}."),
            backgroundColor: Colors.green,
          ),
        );
        // Kembalikan 'true' untuk memberitahu layar detail agar me-refresh
        Navigator.of(context).pop(true);
      } else {
        throw Exception("Gagal memperbarui data");
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
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Edit ${widget.warga.namaLengkap}")),
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
                      decoration:
                          const InputDecoration(labelText: "Tempat Lahir"),
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
                decoration:
                    const InputDecoration(labelText: "Status Perkawinan"),
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
                controller: _noHpController,
                decoration: const InputDecoration(labelText: "No. HP"),
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
                      decoration:
                          const InputDecoration(labelText: "RT (mis: 001)"),
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          v!.length != 3 ? "Format 3 digit (001)" : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _rwController,
                      decoration:
                          const InputDecoration(labelText: "RW (mis: 001)"),
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
                decoration:
                    const InputDecoration(labelText: "ID Keluarga (KK)"),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _statusDalamKeluargaValue,
                decoration:
                    const InputDecoration(labelText: "Status Dalam Keluarga"),
                items: const [
                  // Saat edit, kita izinkan KEPALA_KELUARGA
                  DropdownMenuItem(value: "KEPALA_KELUARGA", child: Text("Kepala Keluarga")),
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
                onPressed: _isLoading ? null : _submitUpdateWarga,
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