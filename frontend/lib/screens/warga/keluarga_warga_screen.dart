// screens/warga/keluarga_warga_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/models/user_model.dart'; // Untuk class Warga dan Keluarga
import 'package:frontend/state/auth_provider.dart';
import 'package:frontend/screens/warga/Detail_Keluarga_Screen.dart'; // <<< IMPORT INI

const Color _primaryColor = Color(0xFF0E2F60);
const Color _backgroundColor = Color(0xFFF5F5F5);
const Color _accentColor = Color(0xFF3C486B);

class KeluargaWargaScreen extends StatelessWidget {
  const KeluargaWargaScreen({super.key});

  // Widget Bantuan: Detail Row
  Widget _buildDetailRow(String title, String? value, {bool showDivider = true}) {
    String displayValue = value ?? "-";
    
    // Menghandle status dalam keluarga (menghilangkan underscore)
    if (title.toLowerCase().contains("status dalam keluarga")) {
      displayValue = displayValue.replaceAll('_', ' ');
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  displayValue,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
              ),
            ],
          ),
          if (showDivider)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Divider(height: 1, color: Colors.grey[200]),
            ),
        ],
      ),
    );
  }
  
  // Widget Bantuan: Card Wrapper
  // DIBUAT DENGAN OPTION ONTAP
  Widget _buildCardWrapper({required Widget child, EdgeInsets padding = const EdgeInsets.all(16), VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            )
          ],
        ),
        padding: padding,
        child: child,
      ),
    );
  }

  // Widget Bantuan: Section Title
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
    final authProvider = context.watch<AuthProvider>();
    final warga = authProvider.user?.warga;

    if (warga == null) {
      return const Center(child: Text("Data Warga tidak ditemukan."));
    }

    final Keluarga? keluarga = warga.keluarga;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text("Data Keluarga Saya"),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- KARTU DATA PRIBADI ---
            _buildSectionTitle(context, "Data Pribadi"),
            _buildCardWrapper(
              child: Column(
                children: [
                  _buildDetailRow("Nama Lengkap", warga.namaLengkap),
                  _buildDetailRow("NIK", warga.nik),
                  _buildDetailRow("Status Dalam Keluarga", warga.statusDalamKeluarga),
                  _buildDetailRow("No. HP", warga.noHp, showDivider: false),
                ],
              ),
            ),
            
            // --- KARTU DATA KELUARGA (KK) - BLOK KONDISIONAL DENGAN NAVIGASI ---
            
            if (keluarga != null) ...[ // KONDISI 1: Keluarga Lengkap
              _buildSectionTitle(context, "Informasi Kartu Keluarga"),
              _buildCardWrapper(
                onTap: () {
                    // NAVIGASI KE DETAIL KELUARGA (Anggap keluarga.noKk adalah nama keluarga)
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) => DetailKeluargaScreen(
                          idKeluarga: keluarga.id, // ID Keluarga
                          namaKeluarga: keluarga.noKk, // Menggunakan No KK sebagai nama/judul
                        ),
                      ),
                    );
                },
                child: Column(
                  children: [
                    _buildDetailRow("Nomor KK", keluarga.noKk),
                    _buildDetailRow("Kepala Keluarga ID", keluarga.kepalaKeluargaId?.toString()),
                    _buildDetailRow("RT/RW Domisili", "${keluarga.rt} / ${keluarga.rw}"),
                    // Tambahkan indikator bahwa card dapat diklik
                    const Align(
                        alignment: Alignment.centerRight,
                        child: Text("KETUK UNTUK DETAIL >", style: TextStyle(color: _primaryColor, fontSize: 12, fontWeight: FontWeight.bold))),
                    const SizedBox(height: 4), 
                  ],
                ),
              ),
            ] else if (warga.keluargaId != null) ...[ 
            // KONDISI 2: KK ID ada, tapi detail keluarga kosong (Tidak bisa diklik karena data kurang)
              _buildSectionTitle(context, "Informasi Kartu Keluarga"),
              _buildCardWrapper(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      "Nomor KK: ${warga.keluargaId}\nDetail data keluarga tidak termuat. Harap hubungi Admin.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ),
                ),
              ),
            ] else ...[ // KONDISI 3: Belum terdaftar dalam KK
              _buildSectionTitle(context, "Informasi Kartu Keluarga"),
              _buildCardWrapper(
                  child: Center(
                      child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text("Anda belum terdaftar dalam Kartu Keluarga mana pun.", style: TextStyle(color: Colors.grey[700]),
                          ),
                      ),
                  ),
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}