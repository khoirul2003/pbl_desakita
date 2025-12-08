import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:frontend/services/api_service.dart';

class DesaPayPulsaScreen extends StatefulWidget {
  final Color primaryColor;
  final Color accentColor;

  const DesaPayPulsaScreen({
    super.key,
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  State<DesaPayPulsaScreen> createState() => _DesaPayPulsaScreenState();
}

class _DesaPayPulsaScreenState extends State<DesaPayPulsaScreen> {
  final TextEditingController _phoneController = TextEditingController();

  final ApiService _apiService = ApiService();
  bool _submitting = false;

  final List<String> _operators = [
    'Telkomsel',
    'Indosat',
    'XL',
    'Tri',
    'Smartfren',
  ];

  final List<int> _denomList = [10000, 20000, 50000, 100000, 150000];

  String? _selectedOperator;
  int? _selectedDenom;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submitPurchase() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || _selectedOperator == null || _selectedDenom == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Lengkapi nomor HP, operator, dan nominal pulsa."),
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
      const fee = 1500.0;
      final newBalance = await _apiService.payPPOB(
        amount: _selectedDenom!.toDouble(),
        productName: 'Pulsa ${_selectedOperator!}',
        targetNumber: phone,
        fee: fee,
      );

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Pembelian Pulsa Berhasil"),
          content: Text(
            "Pulsa ${formatter.format(_selectedDenom)} untuk nomor $phone "
            "(${_selectedOperator!}) berhasil.\n"
            "Biaya admin: ${formatter.format(fee)}\n"
            "Saldo baru: ${newBalance != null ? formatter.format(newBalance) : '-'}",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // dialog
                Navigator.of(context).pop(true); // kembali, refresh wallet
              },
              child: const Text("Tutup"),
            ),
          ],
        ),
      );
    } on DioException catch (e) {
      String msg = "Pembelian pulsa gagal.";
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        msg = data['message'].toString();
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (_) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Pembelian pulsa gagal.")));
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
        title: const Text("Pembelian Pulsa"),
        backgroundColor: widget.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Isi pulsa menggunakan saldo Desapay (demo).",
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: "Nomor HP",
                hintText: "08xxxxxxxxxx",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: _selectedOperator,
              decoration: InputDecoration(
                labelText: "Operator",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _operators
                  .map(
                    (op) =>
                        DropdownMenuItem<String>(value: op, child: Text(op)),
                  )
                  .toList(),
              onChanged: (val) {
                setState(() {
                  _selectedOperator = val;
                });
              },
            ),
            const SizedBox(height: 16),

            Text(
              "Pilih nominal",
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
                  onSelected: (_) {
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
                onPressed: _submitPurchase,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Bayar Sekarang (Demo)",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),

            const SizedBox(height: 12),
            const Text(
              "Catatan: hanya simulasi. Integrasikan dengan API operator / payment gateway untuk transaksi nyata.",
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
