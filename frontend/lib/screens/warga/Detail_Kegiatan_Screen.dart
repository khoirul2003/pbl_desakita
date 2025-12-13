import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart'; 
import 'package:frontend/models/kegiatan_model.dart'; 
import 'package:frontend/screens/admin/edit_kegiatan_screen.dart'; 
import 'package:frontend/services/api_service.dart';

// --- DEFINISI WARNA PROSCAN ---
const Color _primaryColor = Color(0xFF0E2F60); 
const Color _backgroundColor = Color(0xFFF5F5F5); 
const Color _kegiatanColor = Color(0xFF6C4BA3); 
const Color _upcomingColor = Color(0xFF28A745); 

// HAPUS 'const' dari constructor
class DetailKegiatanScreen extends StatefulWidget {
  final Kegiatan kegiatan;
  const DetailKegiatanScreen({super.key, required this.kegiatan});

  @override
  State<DetailKegiatanScreen> createState() => _DetailKegiatanScreenState();
}

class _DetailKegiatanScreenState extends State<DetailKegiatanScreen> {
  late Kegiatan _kegiatanDetail; 

  // Field ini TIDAK boleh const
  final DateFormat _dateTimeFormat = DateFormat('dd MMMM yyyy, HH:mm');
  final NumberFormat _rupiahFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _kegiatanDetail = widget.kegiatan; 
  }

  // --- FUNGSI NAVIGASI KE EDIT ---
  void _goToEditKegiatan() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditKegiatanScreen(kegiatan: _kegiatanDetail),
        fullscreenDialog: true,
      ),
    );
    
    if (result is Kegiatan) {
      setState(() {
          _kegiatanDetail = result;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kegiatan berhasil diperbarui.")),
      );
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
            // Perbaikan Deprecated: ganti withOpacity(0.08)
            color: Colors.black.withAlpha((0.08 * 255).round()), 
            blurRadius: 16, 
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

  // --- WIDGET: CUSTOM HEADER PROSCAN (TANPA TOMBOL EDIT UNTUK WARGA) ---
  Widget _buildCustomHeader(BuildContext context) {
    // Note: Jika screen ini digunakan untuk Admin/RT/RW, tambahkan logic AuthProvider di sini
    // untuk menampilkan tombol Edit. Karena ini diakses dari KegiatanWargaScreen (view-only),
    // kita asumsikan tombol edit disembunyikan.
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
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 16), 
          const Text(
            "Detail Kegiatan",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          // Tombol Edit Dihilangkan (const SizedBox() jika perlu mengisi ruang)
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final Kegiatan kegiatan = _kegiatanDetail;
    
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

    final formattedBiaya = _rupiahFormatter.format(kegiatan.totalBiaya);

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Column(
        children: [
          _buildCustomHeader(context), 
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
                      
                      Text(
                        "Lokasi: ${kegiatan.lokasi}",
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                      
                      const SizedBox(height: 16),
                      Text(
                        "Biaya Total: ${formattedBiaya}",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _kegiatanColor, 
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
                        _dateTimeFormat.format(kegiatan.tanggalMulai),
                      ),
                      _buildDetailRow(
                        "Selesai",
                        _dateTimeFormat.format(kegiatan.tanggalSelesai),
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