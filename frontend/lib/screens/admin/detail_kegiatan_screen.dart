import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:frontend/models/kegiatan_model.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/screens/admin/edit_kegiatan_screen.dart';

class DetailKegiatanScreen extends StatefulWidget {
  final Kegiatan kegiatan;
  const DetailKegiatanScreen({super.key, required this.kegiatan});

  @override
  State<DetailKegiatanScreen> createState() => _DetailKegiatanScreenState();
}

class _DetailKegiatanScreenState extends State<DetailKegiatanScreen> {
  late Kegiatan _kegiatan;
  final DateFormat _dateFormat = DateFormat('dd MMMM yyyy');
  final DateFormat _timeFormat = DateFormat('HH:mm');

  @override
  void initState() {
    super.initState();
    _kegiatan = widget.kegiatan;
    // Di sini kita tidak perlu fetch ulang, karena data sudah dikirim dari list,
    // kecuali jika kita ingin data pembuatnya, yang bisa kita anggap sudah ter-load.
  }

  // Fungsi untuk navigasi ke halaman edit
  Future<void> _goToEditKegiatan() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditKegiatanScreen(kegiatan: _kegiatan),
        fullscreenDialog: true,
      ),
    );
    // Jika 'true' dikembalikan, refresh UI detail
    if (result == true && mounted) {
      // Kita asumsikan updateKegiatan di EditScreen sudah mengembalikan data baru,
      // tapi untuk kesederhanaan, kita hanya memaksa refresh list di layar manajemen.
      // Di sini kita cukup update state jika diperlukan.
    }
  }

  @override
  Widget build(BuildContext context) {
    String scope = 'Desa';
    if (_kegiatan.rt != null) {
      scope = "RT ${_kegiatan.rt} / RW ${_kegiatan.rw}";
    } else if (_kegiatan.rw != null) {
      scope = "RW ${_kegiatan.rw}";
    }

    // Tentukan status
    final bool isFinished = _kegiatan.tanggalSelesai.isBefore(DateTime.now());
    final Color statusColor = isFinished ? Colors.grey : Colors.green;
    final String statusText = isFinished ? "Selesai" : "Akan Datang";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Detail Kegiatan"),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _goToEditKegiatan,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionTitle(context, "Ringkasan"),
          _buildDetailRow("Nama Kegiatan", _kegiatan.namaKegiatan),
          _buildDetailRow("Status", statusText, color: statusColor),
          _buildDetailRow("Lingkup", scope),

          const SizedBox(height: 16),
          _buildSectionTitle(context, "Jadwal & Lokasi"),

          _buildDetailRow(
            "Mulai",
            "${_dateFormat.format(_kegiatan.tanggalMulai)} Pukul ${_timeFormat.format(_kegiatan.tanggalMulai)}",
          ),
          _buildDetailRow(
            "Selesai",
            "${_dateFormat.format(_kegiatan.tanggalSelesai)} Pukul ${_timeFormat.format(_kegiatan.tanggalSelesai)}",
          ),
          _buildDetailRow("Lokasi", _kegiatan.lokasi),

          const SizedBox(height: 16),
          _buildSectionTitle(context, "Deskripsi"),
          Text(_kegiatan.deskripsi, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  // Helper widget untuk membuat baris detail
  Widget _buildDetailRow(String title, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget untuk judul
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
