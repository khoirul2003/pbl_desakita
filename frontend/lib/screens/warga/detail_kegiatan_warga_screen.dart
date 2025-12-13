import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:frontend/models/kegiatan_model.dart'; 

// --- DEFINISI WARNA PROSCAN ---
const Color _primaryColor = Color(0xFF0E2F60);
const Color _accentColor = Color(0xFF3C486B);
const Color _backgroundColor = Color(0xFFF5F5F5);
const Color _kegiatanColor = Color(0xFF6C4BA3);
const Color _upcomingColor = Color(0xFF28A745);

class DetailKegiatanScreen extends StatelessWidget {
  final Kegiatan kegiatan;
  const DetailKegiatanScreen({super.key, required this.kegiatan});

  Widget _buildCardWrapper({required Widget child, EdgeInsets padding = const EdgeInsets.all(16)}) {
    return Container(
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
    );
  }

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
          const SizedBox(width: 48), 
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    
    final NumberFormat rupiahFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    
    final bool isFinished = kegiatan.tanggalSelesai.isBefore(DateTime.now());
    final String statusText = isFinished ? 'SELESAI' : 'AKAN DATANG';
    final Color statusColor = isFinished ? Colors.grey : _upcomingColor;
    
    final String rt = kegiatan.rt ?? '';
    final String rw = kegiatan.rw ?? '';
    final String scope = (rt.isNotEmpty && rw.isNotEmpty) 
        ? "RT $rt / RW $rw" 
        : (rw.isNotEmpty ? "RW $rw" : "Desa (Umum)");

    final formattedBiaya = rupiahFormatter.format(kegiatan.totalBiaya);


    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Column(
        children: [
          _buildCustomHeader(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              children: [
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