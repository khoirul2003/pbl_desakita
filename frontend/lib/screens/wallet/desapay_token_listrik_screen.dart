import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';

import 'package:frontend/services/api_service.dart';

class DesaPayTokenListrikScreen extends StatefulWidget {
  final Color primaryColor;
  final Color accentColor;
  final Color successColor;

  const DesaPayTokenListrikScreen({
    super.key,
    required this.primaryColor,
    required this.accentColor,
    required this.successColor,
  });

  @override
  State<DesaPayTokenListrikScreen> createState() =>
      _DesaPayTokenListrikScreenState();
}

class _DesaPayTokenListrikScreenState extends State<DesaPayTokenListrikScreen> {
  final TextEditingController _meterController = TextEditingController();
  final List<int> _denomList = [20000, 50000, 100000, 200000, 500000];

  int? _selectedDenom;
  String? _dummyCustomerName;
  bool _submitting = false;

  final ApiService _apiService = ApiService();

  @override
  void dispose() {
    _meterController.dispose();
    super.dispose();
  }

  void _checkCustomer() {
    final meter = _meterController.text.trim();
    if (meter.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Masukkan nomor meter / ID pelanggan.")),
      );
      return;
    }

    // Dummy: generate nama pelanggan dari nomor
    setState(() {
      _dummyCustomerName = "Bpk/Ibu Warga $meter";
    });
  }

  String _generateDummyToken() {
    final rand = Random();
    String token = '';
    for (var i = 0; i < 20; i++) {
      token += rand.nextInt(10).toString();
      if ((i + 1) % 4 == 0 && i != 19) {
        token += ' ';
      }
    }
    return token;
  }

  Future<void> _payToken() async {
    final meter = _meterController.text.trim();
    if (meter.isEmpty || _selectedDenom == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Isi nomor meter dan pilih nominal token."),
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
      const double fee = 2500.0;
      final double amount = _selectedDenom!.toDouble();

      final newBalance = await _apiService.payPPOB(
        amount: amount,
        productName: 'Token Listrik',
        targetNumber: meter,
        fee: fee,
      );

      final token = _generateDummyToken();

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Token Listrik Berhasil"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("ID Pelanggan: $meter"),
              if (_dummyCustomerName != null) Text("Nama: $_dummyCustomerName"),
              const SizedBox(height: 8),
              Text("Nominal: ${formatter.format(amount)}"),
              Text("Biaya admin: ${formatter.format(fee)}"),
              const SizedBox(height: 8),
              Text(
                "Saldo baru: ${newBalance != null ? formatter.format(newBalance) : '-'}",
              ),
              const SizedBox(height: 12),
              const Text(
                "Kode Token:",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              SelectableText(
                token,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: widget.successColor,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Catatan: token ini masih dummy, belum terhubung ke sistem PLN.",
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // dialog
                Navigator.of(context).pop(true); // kembali, trigger refresh
              },
              child: const Text("Tutup"),
            ),
          ],
        ),
      );
    } on DioException catch (e) {
      String msg = "Pembelian token listrik gagal.";
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        msg = data['message'].toString();
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pembelian token listrik gagal.")),
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
        title: const Text("Token Listrik"),
        backgroundColor: widget.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Beli token listrik menggunakan saldo Desapay.",
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _meterController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "No. Meter / ID Pelanggan",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _submitting ? null : _checkCustomer,
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text("Cek Pelanggan"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (_dummyCustomerName != null)
                  Expanded(
                    child: Text(
                      _dummyCustomerName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              "Pilih nominal token",
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: widget.accentColor,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _denomList.map((amount) {
                final selected = _selectedDenom == amount;
                return ChoiceChip(
                  label: Text(formatter.format(amount)),
                  selected: selected,
                  onSelected: _submitting
                      ? null
                      : (_) {
                          setState(() {
                            _selectedDenom = amount;
                          });
                        },
                  selectedColor: widget.primaryColor.withOpacity(0.15),
                  labelStyle: TextStyle(
                    color: selected ? widget.primaryColor : Colors.black87,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 12,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _payToken,
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
                        "Bayar & Dapatkan Token",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Catatan: token & data pelanggan masih simulasi. Backend baru mencatat transaksi & mengurangi saldo.",
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
