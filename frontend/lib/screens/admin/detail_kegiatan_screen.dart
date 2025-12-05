import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// Asumsi model Kegiatan ada di sini (sesuaikan path ini jika perlu)
import 'package:frontend/models/kegiatan_model.dart'; 
// Asumsi service dan provider tidak digunakan di StatelessWidget, tapi dipertahankan untuk referensi
import 'package:frontend/services/api_service.dart';
import 'package:frontend/screens/admin/edit_kegiatan_screen.dart';
import 'package:frontend/screens/placeholder_screen.dart';

// --- DEFINISI WARNA PROSCAN ---
const Color _primaryColor = Color(0xFF0E2F60); // Biru Tua
const Color _accentColor = Color(0xFF3C486B); // Aksen Biru/Abu
const Color _backgroundColor = Color(0xFFF5F5F5); // Abu-abu muda untuk Scaffold
const Color _kegiatanColor = Color(0xFF6C4BA3); // Warna khas Kegiatan (Ungu)
const Color _upcomingColor = Color(0xFF28A745); // Hijau untuk Status Akan Datang

// DIUBAH MENJADI STATEFULWIDGET
class DetailKegiatanScreen extends StatefulWidget {
  final Kegiatan kegiatan;
  const DetailKegiatanScreen({super.key, required this.kegiatan});

  @override
  State<DetailKegiatanScreen> createState() => _DetailKegiatanScreenState();
}

class _DetailKegiatanScreenState extends State<DetailKegiatanScreen> {
  // Kita akan menggunakan _kegiatanDetail untuk potensi refresh data, 
  // meskipun dalam contoh ini kita hanya menggunakan widget.kegiatan
  late Kegiatan _kegiatanDetail;

  @override
  void initState() {
    super.initState();
    _kegiatanDetail = widget.kegiatan;
    // Tambahkan fetch detail jika perlu update real-time: _fetchKegiatanDetail();
  }

  // --- FUNGSI NAVIGASI KE EDIT ---
  void _goToEditKegiatan() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditKegiatanScreen(kegiatan: _kegiatanDetail),
        fullscreenDialog: true,
      ),
    );
    
    // Logika refresh data setelah kembali dari edit (jika diperlukan)
    if (result == true) {
      // Di sini seharusnya ada logika untuk mengambil data terbaru
      // Contoh: _fetchKegiatanDetail();
    }
  }

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
      // Padding atas disesuaikan untuk konsistensi
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

  // --- WIDGET: CUSTOM HEADER PROSCAN (DENGAN TOMBOL EDIT) ---
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
            "Detail Kegiatan",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          // TOMBOL EDIT BARU
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: _goToEditKegiatan,
          ), 
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final Kegiatan kegiatan = _kegiatanDetail; // Menggunakan stateful detail
    
    final NumberFormat rupiahFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    
    // Logika Status
    final bool isFinished = kegiatan.tanggalSelesai.isBefore(DateTime.now());
    final String statusText = isFinished ? 'SELESAI' : 'AKAN DATANG';
    final Color statusColor = isFinished ? Colors.grey : _upcomingColor;
    
    // Format Lingkup RT/RW
    final String rt = kegiatan.rt ?? '';
    final String rw = kegiatan.rw ?? '';
    final String scope = (rt.isNotEmpty && rw.isNotEmpty) 
        ? "RT $rt / RW $rw" 
        : (rw.isNotEmpty ? "RW $rw" : "Desa (Umum)");

    // Format Biaya
    final formattedBiaya = rupiahFormatter.format(kegiatan.totalBiaya);


    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Column(
        children: [
          _buildCustomHeader(context), // Mengganti AppBar
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              children: [
                // --- KARTU RINGKASAN KEGIATAN ---
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
                          Icon(Icons.event_note, color: statusColor, size: 24),
                        ],
                      ),
                      const Divider(height: 20, thickness: 1),
                      
                      Text(
                        kegiatan.namaKegiatan,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: _primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Display Lokasi
                      Text(
                        "Lokasi: ${kegiatan.lokasi}",
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                      
                      const SizedBox(height: 16),
                      Text(
                        "Biaya Total: ${formattedBiaya}",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _kegiatanColor, // Warna khas Kegiatan
                        ),
                      ),
                    ],
                  ),
                ),

                // --- RINCIAN JADWAL & LINGKUP ---
                _buildSectionTitle(context, "Jadwal dan Lingkup"),
                _buildCardWrapper(
                  child: Column(
                    children: [
                      _buildDetailRow(
                        "Mulai",
                        DateFormat('dd MMMM yyyy, HH:mm').format(kegiatan.tanggalMulai),
                      ),
                      _buildDetailRow(
                        "Selesai",
                        DateFormat('dd MMMM yyyy, HH:mm').format(kegiatan.tanggalSelesai),
                      ),
                      const Divider(height: 1, thickness: 1, color: Colors.grey),
                      _buildDetailRow("Lingkup Area", scope),
                    ],
                  ),
                ),

                // --- KETERANGAN ---
                _buildSectionTitle(context, "Deskripsi Kegiatan"),
                _buildCardWrapper(
                  child: Text(
                    kegiatan.deskripsi, 
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