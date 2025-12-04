import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:frontend/models/iuran_model.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/screens/admin/edit_iuran_screen.dart';
import 'package:frontend/screens/placeholder_screen.dart'; // Untuk tombol Lihat Tagihan

// --- DEFINISI WARNA PROSCAN ---
const Color _primaryColor = Color(0xFF0E2F60); // Biru Tua
const Color _accentColor = Color(0xFF3C486B); // Aksen Biru/Abu
const Color _backgroundColor = Color(0xFFF5F5F5); // Abu-abu muda untuk Scaffold
const Color _successColor = Color(0xFF28A745); // Hijau untuk Jumlah/Aksi Utama

class DetailIuranScreen extends StatefulWidget {
  final Iuran iuran;
  const DetailIuranScreen({super.key, required this.iuran});

  @override
  State<DetailIuranScreen> createState() => _DetailIuranScreenState();
}

class _DetailIuranScreenState extends State<DetailIuranScreen> {
  late Iuran _iuran;
  // Variabel _isGenerating dipertahankan, meskipun fungsinya dihapus dari UI
  bool _isGenerating = false; 

  final NumberFormat _rupiahFormatter = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _iuran = widget.iuran;
  }

  // Navigasi ke halaman edit
  Future<void> _goToEditIuran() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditIuranScreen(iuran: _iuran),
        fullscreenDialog: true,
      ),
    );
    // Jika 'true' dikembalikan, data diasumsikan diupdate.
  }

  // Fungsi generate tagihan tetap ada di sini (sebagai simulasi)
  Future<void> _generateTagihan() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      await Future.delayed(const Duration(seconds: 1)); 

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Simulasi: Tagihan untuk ${_iuran.namaIuran} (Bulan Ini) berhasil dibuat!",
            ),
            backgroundColor: _primaryColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal Generate Tagihan: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }
  
  // --- WIDGET: CUSTOM HEADER ---
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
            "Detail Jenis Iuran",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: _goToEditIuran,
          ),
        ],
      ),
    );
  }

  // --- WIDGET: KARTU UTAMA/HEADER IURAN ---
  Widget _buildIuranHeaderCard(BuildContext context) {
    return _buildCardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: _primaryColor.withOpacity(0.1),
                child: Icon(
                  _iuran.tipe == 'PER_KELUARGA' ? Icons.house_rounded : Icons.person_rounded,
                  color: _primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _iuran.namaIuran,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _accentColor,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          const Text(
            "Jumlah Tagihan",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _rupiahFormatter.format(_iuran.jumlah),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: _successColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _iuran.deskripsi ?? "Tidak ada deskripsi yang tersedia untuk jenis iuran ini.",
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
        ],
      ),
    );
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

  // --- WIDGET BANTUAN: DETAIL ROW (Di dalam kartu) ---
  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
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
  
  // --- WIDGET BANTUAN: SECTION TITLE (Di luar kartu) ---
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0, left: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: _primaryColor, 
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String scope = 'Desa';
    if (_iuran.rt != null) {
      scope = "RT ${_iuran.rt} / RW ${_iuran.rw}";
    } else if (_iuran.rw != null) {
      scope = "RW ${_iuran.rw}";
    }

    final String tipeText = _iuran.tipe.replaceAll('_', ' ');

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Column(
        children: [
          _buildCustomHeader(context), 
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
              children: [
                // --- KARTU HEADER IURAN (Nama, Jumlah, Deskripsi) ---
                _buildIuranHeaderCard(context),

                // --- RINCIAN PENAGIHAN ---
                _buildSectionTitle(context, "Rincian Penagihan"),
                _buildCardWrapper(
                  child: Column(
                    children: [
                      _buildDetailRow("Tipe Penagihan", tipeText),
                      _buildDetailRow("Lingkup Area", scope),
                    ],
                  ),
                ),

                // --- BAGIAN 'AKSI CEPAT' TELAH DIHAPUS DARI SINI ---
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}