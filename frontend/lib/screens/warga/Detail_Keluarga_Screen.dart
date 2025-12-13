import 'package:flutter/material.dart';

const Color _primaryColor = Color(0xFF0E2F60); 

class DetailKeluargaScreen extends StatelessWidget {
  final int idKeluarga;
  final String namaKeluarga;

  const DetailKeluargaScreen({
    super.key,
    required this.idKeluarga,
    required this.namaKeluarga,
  });

  @override
  Widget build(BuildContext context) {
    // Dummy Data Detail Keluarga
    final List<Map<String, String>> anggota = [
      {"nama": "Budi Santoso (Kepala Keluarga)", "status": "WNI, Pria, 45 tahun"},
      {"nama": "Siti Aminah (Istri)", "status": "WNI, Wanita, 40 tahun"},
      {"nama": "Ahmad Dani (Anak)", "status": "WNI, Pria, 15 tahun"},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text("Detail KK: $namaKeluarga"),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("ID KK: #$idKeluarga", style: Theme.of(context).textTheme.headlineSmall),
            const Divider(height: 30),
            Text("Anggota Keluarga (${anggota.length} Orang):", 
                 style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: _primaryColor)),
            const SizedBox(height: 10),
            ...anggota.map((a) => ListTile(
                  leading: const Icon(Icons.person, color: _primaryColor),
                  title: Text(a['nama']!),
                  subtitle: Text(a['status']!),
                )).toList(),
            const Divider(height: 30),
            // Informasi tambahan (dummy)
            const Text("Alamat Domisili:", style: TextStyle(fontWeight: FontWeight.bold)),
            const Text("Jl. Merdeka No. 15, RT 001/RW 001"),
            const SizedBox(height: 10),
            const Text("Catatan Iuran Terakhir:", style: TextStyle(fontWeight: FontWeight.bold)),
            const Text("Lunas sampai bulan November 2025."),
          ],
        ),
      ),
    );
  }
}