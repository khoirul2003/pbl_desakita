import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:frontend/models/keuangan_model.dart';
import 'package:frontend/services/api_service.dart';
import 'package:provider/provider.dart';
// Import untuk layar edit (jika Anda membuat edit_keuangan_screen.dart)

class DetailKeuanganScreen extends StatelessWidget {
  final Keuangan keuangan;
  const DetailKeuanganScreen({super.key, required this.keuangan});

  @override
  Widget build(BuildContext context) {
    final NumberFormat rupiahFormatter = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    final bool isPemasukan = keuangan.tipe == 'PEMASUKAN';
    final Color color = isPemasukan ? Colors.green : Colors.red;
    final String scope = keuangan.rt != null
        ? "RT ${keuangan.rt}/${keuangan.rw}"
        : "Umum (Desa)";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Detail Transaksi Keuangan"),
        actions: [
          // Tombol Edit (TODO: buat layar edit)
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Navigasi ke EditKeuanganScreen
            },
          ),
          // Tombol Hapus (TODO: buat fungsi hapus di ApiService)
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              // TODO: Panggil fungsi delete
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- Ringkasan Nilai ---
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isPemasukan ? "PEMASUKAN" : "PENGELUARAN",
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.copyWith(color: color),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    rupiahFormatter.format(keuangan.jumlah),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    keuangan.keterangan,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // --- Detail Transaksi ---
          _buildSectionTitle(context, "Rincian Detail"),
          _buildDetailRow("Tipe Transaksi", keuangan.tipe),
          _buildDetailRow(
            "Tanggal Transaksi",
            DateFormat('dd MMMM yyyy').format(keuangan.tanggal),
          ),
          _buildDetailRow("Lingkup Kas", scope),
          // _buildDetailRow("Dicatat Oleh", keuangan.pencatat?.namaLengkap ?? "Admin/Sistem"), // Jika model lengkap
          _buildDetailRow(
            "Waktu Catat",
            DateFormat('HH:mm').format(keuangan.tanggal),
          ),

          const SizedBox(height: 16),
          _buildSectionTitle(context, "Keterangan"),
          Text(keuangan.keterangan, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  // Helper widget untuk membuat baris detail
  Widget _buildDetailRow(String title, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: color,
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
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
