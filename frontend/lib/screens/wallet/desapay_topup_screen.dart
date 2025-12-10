import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';

// Asumsi: Anda memiliki file ini di folder yang benar
import 'package:frontend/services/api_service.dart'; 

// Konstanta untuk BorderRadius (sesuai permintaan 12dp)
const double _kBorderRadius = 12.0;

class DesaPayTopUpScreen extends StatefulWidget {
  final Color primaryColor;
  final Color accentColor;

  const DesaPayTopUpScreen({
    super.key,
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  State<DesaPayTopUpScreen> createState() => _DesaPayTopUpScreenState();
}

class _DesaPayTopUpScreenState extends State<DesaPayTopUpScreen> {
  final TextEditingController _amountController = TextEditingController();
  final List<int> _quickAmounts = [25000, 50000, 100000, 200000];

  // Asumsi: ApiService sudah memiliki method topUpWallet yang valid
  final ApiService _apiService = ApiService();
  bool _submitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _fillQuickAmount(int amount) {
    // Mengisi text field dengan jumlah tanpa mengubah formatnya dulu
    _amountController.text = amount.toString();
  }

  Future<void> _submitTopUp() async {
    // Membersihkan input (menghapus titik/koma) sebelum parsing
    final raw = _amountController.text.replaceAll('.', '').replaceAll(',', '');
    final int amount = int.tryParse(raw) ?? 0;

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Masukkan nominal top up yang valid")),
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
      // Panggil API top up
      final newBalance = await _apiService.topUpWallet(amount.toDouble());

      // --- Dialog Sukses (Gaya ProScan) ---
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          // KUNCI: Sudut membulat pada Dialog
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text("Top Up Berhasil"),
          content: Text(
            "Top up sebesar ${formatter.format(amount)} berhasil.\n"
            "Saldo baru: ${newBalance != null ? formatter.format(newBalance) : '-'}",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // tutup dialog
                Navigator.of(
                  context,
                ).pop(true); // kembali ke Home, trigger refresh
              },
              child: Text(
                "Tutup",
                // KUNCI: Menggunakan primaryColor untuk TextButton
                style: TextStyle(color: widget.primaryColor, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    } on DioException catch (e) {
      String msg = "Top up gagal.";
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        msg = data['message'].toString();
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Top up gagal. Terjadi kesalahan.")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      // --- APP BAR (Gaya ProScan) ---
      appBar: AppBar(
        title: const Text("Top Up Desapay"),
        backgroundColor: widget.primaryColor, // Biru Tua/Navy
        foregroundColor: Colors.white,
        elevation: 0, // Tampilan flat/modern
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0), // Padding sedikit lebih besar
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- BAGIAN DESKRIPSI (Gaya ProScan) ---
            Text(
              "Top up saldo Desapay.",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800, // Sangat tebal
                color: widget.accentColor, // Warna Aksen Cerah
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Masukkan nominal top up atau pilih dari opsi cepat di bawah.",
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 28), 
            
            // --- INPUT NOMINAL TOP UP (Gaya ProScan) ---
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Nominal Top Up",
                prefixText: "Rp ",
                labelStyle: TextStyle(color: Colors.grey.shade600),
                // KUNCI: Border dengan sudut membulat
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(_kBorderRadius),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(_kBorderRadius),
                  borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(_kBorderRadius),
                  // Border fokus dengan warna primary
                  borderSide: BorderSide(color: widget.primaryColor, width: 2), 
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // --- OPSI CEPAT (QUICK AMOUNTS - Gaya ProScan) ---
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _quickAmounts.map((e) {
                return OutlinedButton(
                  onPressed: () => _fillQuickAmount(e),
                  style: OutlinedButton.styleFrom(
                    // Style minimalis
                    foregroundColor: widget.primaryColor,
                    side: BorderSide(color: widget.primaryColor.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  child: Text(
                    formatter.format(e),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 40),
            
            // --- TOMBOL UTAMA (SUBMIT BUTTON - Gaya ProScan) ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submitTopUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    // KUNCI: Sudut membulat 12
                    borderRadius: BorderRadius.circular(_kBorderRadius),
                  ),
                  elevation: 5, // Shadow lembut
                ),
                child: _submitting
                    ? const SizedBox(
                        height: 20, 
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        "Top Up Sekarang",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}