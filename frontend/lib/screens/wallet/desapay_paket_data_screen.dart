import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';

import 'package:frontend/services/api_service.dart';

class DesaPayPaketDataScreen extends StatefulWidget {
  final Color primaryColor;
  final Color accentColor;

  const DesaPayPaketDataScreen({
    super.key,
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  State<DesaPayPaketDataScreen> createState() => _DesaPayPaketDataScreenState();
}

class _DesaPayPaketDataScreenState extends State<DesaPayPaketDataScreen> {
  final TextEditingController _phoneController = TextEditingController();

  final List<String> _operators = [
    'Telkomsel',
    'Indosat',
    'XL',
    'Tri',
    'Smartfren',
  ];

  String? _selectedOperator;

  final List<Map<String, dynamic>> _dummyPackages = [
    {
      'name': 'Paket Harian 1GB',
      'detail': 'Masa aktif 1 hari',
      'quota': '1 GB',
      'price': 10000,
    },
    {
      'name': 'Paket Mingguan 5GB',
      'detail': 'Masa aktif 7 hari',
      'quota': '5 GB',
      'price': 35000,
    },
    {
      'name': 'Paket Bulanan 10GB',
      'detail': 'Masa aktif 30 hari',
      'quota': '10 GB',
      'price': 75000,
    },
    {
      'name': 'Paket Sosmed Unlimited',
      'detail': 'Masa aktif 30 hari, FUP 5GB',
      'quota': 'Unlimited Sosmed',
      'price': 60000,
    },
  ];

  final ApiService _apiService = ApiService();
  bool _submitting = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _buyPackage(Map<String, dynamic> pkg) async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || _selectedOperator == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Isi nomor HP dan pilih operator terlebih dahulu."),
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
      const double fee = 1500.0;
      final double amount = (pkg['price'] as num).toDouble();

      final newBalance = await _apiService.payPPOB(
        amount: amount,
        productName: 'Paket Data ${_selectedOperator!} - ${pkg['name']}',
        targetNumber: phone,
        fee: fee,
      );

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Pembelian Paket Data Berhasil"),
          content: Text(
            "Paket: ${pkg['name']} (${pkg['quota']})\n"
            "Nomor: $phone (${_selectedOperator!})\n"
            "Harga: ${formatter.format(amount)}\n"
            "Biaya admin: ${formatter.format(fee)}\n\n"
            "Saldo baru: ${newBalance != null ? formatter.format(newBalance) : '-'}",
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
      String msg = "Pembelian paket data gagal.";
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        msg = data['message'].toString();
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pembelian paket data gagal.")),
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
        title: const Text("Paket Data"),
        backgroundColor: widget.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Pilih paket data untuk nomor Anda.",
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                ),
                const SizedBox(height: 12),
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
                const SizedBox(height: 8),
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
                        (op) => DropdownMenuItem<String>(
                          value: op,
                          child: Text(op),
                        ),
                      )
                      .toList(),
                  onChanged: _submitting
                      ? null
                      : (val) {
                          setState(() {
                            _selectedOperator = val;
                          });
                        },
                ),
              ],
            ),
          ),
          const Divider(height: 0),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _dummyPackages.length,
              itemBuilder: (context, index) {
                final pkg = _dummyPackages[index];
                final double price = (pkg['price'] as num).toDouble();

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: widget.primaryColor.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            pkg['quota'],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                              color: widget.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pkg['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                pkg['detail'],
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formatter.format(price),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: widget.accentColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _submitting
                              ? null
                              : () => _buyPackage(pkg),
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
                          child: _submitting
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  "Beli",
                                  style: TextStyle(fontSize: 12),
                                ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
