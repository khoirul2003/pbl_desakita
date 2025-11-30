import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:frontend/models/iuran_model.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/screens/admin/edit_iuran_screen.dart';
import 'package:frontend/screens/placeholder_screen.dart';

class DetailIuranScreen extends StatefulWidget {
  final Iuran iuran;
  const DetailIuranScreen({super.key, required this.iuran});

  @override
  State<DetailIuranScreen> createState() => _DetailIuranScreenState();
}

class _DetailIuranScreenState extends State<DetailIuranScreen> {
  late Iuran _iuran;
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
    // Jika 'true' dikembalikan, kita asumsikan data sudah diupdate di sana
    // dan kita perlu refresh list di manajemen iuran.
  }

  // TODO: FUNGSI GENERATE TAGIHAN (API BARU DI LARAVEL)
  Future<void> _generateTagihan() async {
    // Ini membutuhkan endpoint POST /api/v1/iuran/{id}/generate-tagihan di Laravel.
    // Kita simulasikan dulu.
    setState(() {
      _isGenerating = true;
    });

    try {
      await Future.delayed(const Duration(seconds: 1)); // Simulasi API call

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Simulasi: Tagihan untuk ${_iuran.namaIuran} berhasil dibuat.",
            ),
            backgroundColor: Colors.blue,
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

  @override
  Widget build(BuildContext context) {
    String scope = 'Desa';
    if (_iuran.rt != null) {
      scope = "RT ${_iuran.rt} / RW ${_iuran.rw}";
    } else if (_iuran.rw != null) {
      scope = "RW ${_iuran.rw}";
    }

    // Tipe
    final String tipeText = _iuran.tipe.replaceAll('_', ' ');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Detail Jenis Iuran"),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: _goToEditIuran),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- Bagian Header ---
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _iuran.namaIuran,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _rupiahFormatter.format(_iuran.jumlah),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(_iuran.deskripsi ?? "Tidak ada deskripsi."),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          _buildSectionTitle(context, "Rincian Penagihan"),

          _buildDetailRow("Tipe Penagihan", tipeText),
          _buildDetailRow("Lingkup Area", scope),

          const SizedBox(height: 24),
          _buildSectionTitle(context, "Aksi Cepat"),

          // Tombol Generate Tagihan
          ElevatedButton.icon(
            onPressed: _isGenerating ? null : _generateTagihan,
            icon: _isGenerating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.receipt_long),
            label: Text(
              _isGenerating ? "MEMBUAT TAGIHAN..." : "BUAT TAGIHAN BULAN INI",
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 12),

          // Tombol Lihat Tagihan
          OutlinedButton.icon(
            onPressed: () {
              // Navigasi ke Placeholder Kelola Tagihan
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PlaceholderScreen(
                    title: "Kelola Tagihan: ${_iuran.namaIuran}",
                  ),
                ),
              );
            },
            icon: const Icon(Icons.list_alt),
            label: const Text("LIHAT RIWAYAT & KELOLA TAGIHAN"),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget untuk membuat baris detail
  Widget _buildDetailRow(String title, String value) {
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
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
