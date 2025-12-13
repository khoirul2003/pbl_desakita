import 'package:flutter/material.dart';

const Color _primaryColor = Color(0xFF0E2F60); 

class DetailAcaraScreen extends StatelessWidget {
  final int idAcara;
  final String judulAcara;

  const DetailAcaraScreen({
    super.key,
    required this.idAcara,
    required this.judulAcara,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Detail Acara: $judulAcara"),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(judulAcara, style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: _primaryColor)),
            const Divider(height: 30),
            _buildDetailRow(Icons.event, "Tanggal", "15 Desember 2025"),
            _buildDetailRow(Icons.schedule, "Waktu", "19:00 - Selesai"),
            _buildDetailRow(Icons.location_on, "Lokasi", "Balai Warga RW 001"),
            const Divider(height: 30),
            Text("Deskripsi Acara:", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              "Acara Syukuran Akhir Tahun dan Pembagian Donasi untuk anak yatim. Diharapkan kehadiran seluruh warga.",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            Text("Kontak Panitia:", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const Text("Bapak Joko (RT 002) - 0812xxxxxx"),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _primaryColor, size: 24),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(value, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }
}