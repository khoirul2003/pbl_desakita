import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';

import 'package:frontend/services/api_service.dart';

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

  final ApiService _apiService = ApiService();
  bool _submitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _fillQuickAmount(int amount) {
    _amountController.text = amount.toString();
  }

  Future<void> _submitTopUp() async {
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
      final newBalance = await _apiService.topUpWallet(amount.toDouble());

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
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
              child: const Text("Tutup"),
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
      appBar: AppBar(
        title: const Text("Top Up Desapay"),
        backgroundColor: widget.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Top up saldo Desapay.",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: widget.accentColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Masukkan nominal top up atau pilih dari opsi cepat di bawah.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Nominal Top Up",
                prefixText: "Rp ",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickAmounts.map((e) {
                return OutlinedButton(
                  onPressed: () => _fillQuickAmount(e),
                  child: Text(formatter.format(e)),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submitTopUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        "Top Up Sekarang",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
