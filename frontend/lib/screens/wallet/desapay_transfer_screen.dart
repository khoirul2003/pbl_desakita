import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';

import 'package:frontend/services/api_service.dart';

// Konstanta untuk Gaya ProScan
const double _kBorderRadius = 12.0;
const double _kCardRadius = 16.0;

class DesaPayTransferScreen extends StatefulWidget {
  final Color primaryColor;
  final Color accentColor;

  const DesaPayTransferScreen({
    super.key,
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  State<DesaPayTransferScreen> createState() => _DesaPayTransferScreenState();
}

class _DesaPayTransferScreenState extends State<DesaPayTransferScreen> {
  final TextEditingController _targetAccountController =
      TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  final ApiService _apiService = ApiService();
  bool _submitting = false;

  @override
  void dispose() {
    _targetAccountController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submitTransfer() async {
    final target = _targetAccountController.text.trim();
    final rawAmount = _amountController.text
        .replaceAll('.', '')
        .replaceAll(',', '');
    final amount = int.tryParse(rawAmount) ?? 0;
    final note = _noteController.text.trim().isEmpty
        ? null
        : _noteController.text.trim();

    if (target.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Isi nomor akun tujuan dan nominal transfer dengan benar",
          ),
        ),
      );
      return;
    }

    setState(() {
      _submitting = true;
    });

    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    try {
      final newBalance = await _apiService.transferWallet(
        accountNumberReceiver: target,
        amount: amount.toDouble(),
        notes: note,
      );

      // --- DIALOG SUKSES (Gaya ProScan) ---
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          // Sudut membulat pada dialog
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            "Transfer Berhasil",
            style: TextStyle(
                color: widget.primaryColor, fontWeight: FontWeight.bold),
          ),
          content: Text(
            "Transfer ke akun $target sebesar ${formatter.format(amount)} berhasil.\n"
            "Saldo baru: ${newBalance != null ? formatter.format(newBalance) : '-'}",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // dialog
                Navigator.of(context).pop(true); // screen, trigger refresh
              },
              // Warna TextButton menggunakan Primary Color
              child: Text("Tutup", style: TextStyle(color: widget.primaryColor)),
            ),
          ],
        ),
      );
    } on DioException catch (e) {
      String msg = "Transfer gagal.";
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        msg = data['message'].toString();
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Transfer gagal. Terjadi kesalahan.")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  // --- WIDGET HEADER MELENGKUNG (DIADAPTASI DARI MANAJEMEN KEGIATAN) ---
  Widget _buildCurvedHeader(BuildContext context) {
    final bool canPop = Navigator.of(context).canPop();

    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 20),
      decoration: BoxDecoration(
        color: widget.primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Tombol Back
            if (canPop)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              )
            else
              const SizedBox(width: 0),

            // Judul
            Expanded(
              child: Text(
                "Transfer Antar Desapay",
                textAlign: canPop ? TextAlign.left : TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Placeholder di kanan (untuk menyeimbangkan tombol back)
            if (canPop) const SizedBox(width: 48)
          ],
        ),
      ),
    );
  }

  // Fungsi untuk mendapatkan InputDecoration bergaya ProScan
  InputDecoration _proscanInputDecoration({
    required String labelText,
    String? hintText,
    String? prefixText,
    Widget? suffixIcon, // Tambahkan suffixIcon untuk kontak
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixText: prefixText,
      suffixIcon: suffixIcon,
      labelStyle: TextStyle(color: Colors.grey.shade600),

      // KUNCI: Sudut membulat (12dp) pada border
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_kBorderRadius),
        borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_kBorderRadius),
        borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
      ),
      // Aksen Warna saat fokus
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_kBorderRadius),
        borderSide: BorderSide(color: widget.accentColor, width: 2),
      ),
      contentPadding:
          const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );
  }

  // --- START WIDGET BUILD ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          // Panggil header kustom
          _buildCurvedHeader(context),

          // Konten Utama
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0), // Padding lebih besar
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- HEADER DESKRIPSI (Gaya ProScan) ---
                  Text(
                    "Transfer Saldo",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800, // Lebih tebal
                          color: widget.primaryColor, // Warna Primary
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Masukkan nomor akun tujuan dan nominal transfer.",
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 30),

                  // --- INPUT NO. AKUN TUJUAN ---
                  TextField(
                    controller: _targetAccountController,
                    keyboardType: TextInputType.text,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    decoration: _proscanInputDecoration(
                      labelText: "No. Akun Tujuan",
                      hintText: "DSP-00**",
                      suffixIcon: Icon(Icons.person_search_rounded,
                          color: widget.accentColor),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- INPUT NOMINAL TRANSFER ---
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    decoration: _proscanInputDecoration(
                      labelText: "Nominal Transfer",
                      prefixText: "Rp ",
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- INPUT CATATAN (OPSIONAL) ---
                  TextField(
                    controller: _noteController,
                    maxLines: 3, // Perbesar field catatan
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    decoration: _proscanInputDecoration(
                      labelText: "Catatan (opsional)",
                    ),
                  ),
                  const SizedBox(height: 40),

                  // --- TOMBOL SUBMIT (Gaya ProScan) ---
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submitTransfer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.primaryColor,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 18), // Padding lebih besar
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(_kBorderRadius),
                        ),
                        elevation: 5,
                        shadowColor: widget.primaryColor.withOpacity(0.4),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              "Kirim",
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}