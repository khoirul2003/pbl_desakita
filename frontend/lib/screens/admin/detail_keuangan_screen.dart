import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:frontend/models/keuangan_model.dart';
import 'package:frontend/services/api_service.dart';
import 'package:provider/provider.dart';
// Import untuk layar edit (jika Anda membuat edit_keuangan_screen.dart)

// --- DEFINISI WARNA PROSCAN ---
const Color _primaryColor = Color(0xFF0E2F60); // Biru Tua
const Color _accentColor = Color(0xFF3C486B); // Aksen Biru/Abu
const Color _backgroundColor = Color(0xFFF5F5F5); // Abu-abu muda untuk Scaffold
const Color _successColor = Color(0xFF28A745); // Hijau untuk Pemasukan
const Color _expenseColor = Colors.red; // Merah untuk Pengeluaran

class DetailKeuanganScreen extends StatelessWidget {
  final Keuangan keuangan;
  const DetailKeuanganScreen({super.key, required this.keuangan});

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
      padding: const EdgeInsets.symmetric(vertical: 8.0),
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
            "Detail Transaksi",
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

    final bool isPemasukan = keuangan.tipe == 'PEMASUKAN';
    final Color amountColor = isPemasukan ? _successColor : _expenseColor;
    final String scope = keuangan.rt != null
        ? "RT ${keuangan.rt}/${keuangan.rw}"
        : "Umum (Desa)";

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Column(
        children: [
          _buildCustomHeader(context), // Mengganti AppBar
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
              children: [
                // --- KARTU RINGKASAN NILAI ---
                _buildCardWrapper(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isPemasukan ? Icons.add_circle_outline : Icons.remove_circle_outline,
                            color: amountColor,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isPemasukan ? "PEMASUKAN" : "PENGELUARAN",
                            style: Theme.of(
                              context,
                            ).textTheme.titleSmall?.copyWith(color: amountColor, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Divider(height: 20, thickness: 1),
                      const Text("Nilai Transaksi", style: TextStyle(color: Colors.grey, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(
                        rupiahFormatter.format(keuangan.jumlah),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: amountColor,
                          fontSize: 28,
                        ),
                      ),
                    ],
                  ),
                ),

                // --- KARTU RINCIAN DETAIL & KAS ---
                _buildSectionTitle(context, "Rincian Transaksi"),
                _buildCardWrapper(
                  child: Column(
                    children: [
                      _buildDetailRow("Tipe Transaksi", keuangan.tipe),
                      _buildDetailRow(
                        "Tanggal",
                        DateFormat('dd MMMM yyyy').format(keuangan.tanggal),
                      ),
                      _buildDetailRow("Lingkup Kas", scope),
                      _buildDetailRow(
                        "Waktu Catat",
                        DateFormat('HH:mm').format(keuangan.tanggal),
                      ),
                    ],
                  ),
                ),

                // --- KARTU KETERANGAN ---
                _buildSectionTitle(context, "Keterangan Lengkap"),
                _buildCardWrapper(
                  child: Text(
                    keuangan.keterangan, 
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