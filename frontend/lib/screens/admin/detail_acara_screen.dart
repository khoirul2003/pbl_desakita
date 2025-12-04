import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
// Asumsi model Acara ada di sini
import 'package:frontend/models/acara_model.dart'; 
import 'package:frontend/services/api_service.dart';

// --- DEFINISI WARNA PROSCAN ---
const Color _primaryColor = Color(0xFF0E2F60); // Biru Tua
const Color _accentColor = Color(0xFF3C486B); // Aksen Biru/Abu
const Color _backgroundColor = Color(0xFFF5F5F5); // Abu-abu muda untuk Scaffold
const Color _eventColor = Colors.redAccent; // Warna untuk Biaya
const Color _upcomingColor = Color(0xFF28A745); // Hijau untuk Status Akan Datang

class DetailAcaraScreen extends StatelessWidget {
  final Acara acara;
  const DetailAcaraScreen({super.key, required this.acara});

  // --- WIDGET BANTUAN: CARD WRAPPER DENGAN SHADOW PROSCAN ---
  Widget _buildCardWrapper({required Widget child, EdgeInsets padding = const EdgeInsets.all(16)}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16, // Shadow menonjol dan lembut
            offset: const Offset(0, 6),
          )
        ],
      ),
      padding: padding,
      child: child,
    );
  }

  // Helper widget untuk membuat baris detail
  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
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
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget untuk judul
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0, left: 4),
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

  // --- WIDGET: CUSTOM HEADER PROSCAN (tanpa aksi edit/hapus) ---
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Text(
            "Detail Acara",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 48), // Spacer pengganti ikon aksi
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final NumberFormat rupiahFormatter = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    
    // Logika Status
    final bool isFinished = acara.tanggalSelesai.isBefore(DateTime.now());
    final String statusText = isFinished ? 'SELESAI' : 'AKAN DATANG';
    final Color statusColor = isFinished ? Colors.grey : _upcomingColor;
    
    final String scope = acara.rt != null
        ? "RT ${acara.rt} / RW ${acara.rw}"
        : (acara.rw != null ? "RW ${acara.rw}" : "Desa (Umum)");

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Column(
        children: [
          _buildCustomHeader(context), // Mengganti AppBar
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
              children: [
                // --- KARTU RINGKASAN ACARA ---
                _buildCardWrapper(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            statusText,
                            style: Theme.of(
                              context,
                            ).textTheme.titleSmall?.copyWith(color: statusColor, fontWeight: FontWeight.bold),
                          ),
                          Icon(Icons.celebration, color: statusColor, size: 24),
                        ],
                      ),
                      const Divider(height: 20, thickness: 1),
                      
                      Text(
                        acara.namaAcara,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: _primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Lokasi: ${acara.lokasi}",
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                      
                      const SizedBox(height: 16),
                      Text(
                        "Biaya Total: ${rupiahFormatter.format(acara.totalBiaya)}",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _eventColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // --- KARTU RINCIAN JADWAL & LINGKUP ---
                _buildSectionTitle(context, "Jadwal dan Lingkup"),
                _buildCardWrapper(
                  child: Column(
                    children: [
                      _buildDetailRow(
                        "Mulai",
                        DateFormat('dd MMMM yyyy, HH:mm').format(acara.tanggalMulai),
                      ),
                      _buildDetailRow(
                        "Selesai",
                        DateFormat('dd MMMM yyyy, HH:mm').format(acara.tanggalSelesai),
                      ),
                      const Divider(height: 1, thickness: 1, color: Colors.grey),
                      _buildDetailRow("Lingkup Area", scope),
                    ],
                  ),
                ),

                // --- KARTU KETERANGAN ---
                _buildSectionTitle(context, "Deskripsi Acara"),
                _buildCardWrapper(
                  child: Text(
                    acara.deskripsi, 
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}