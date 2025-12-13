import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';

import 'package:frontend/services/api_service.dart';

// Konstanta untuk Gaya ProScan
const double _kBorderRadius = 12.0;
const double _kCardRadius = 16.0;

class DesaPayPaketDataScreen extends StatefulWidget {
  final Color primaryColor; // Navy Blue
  final Color accentColor; // Warna Aksen

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
      'quota': 'Sosmed UNL', // Diperpendek agar pas di ikon
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

  // Fungsi untuk mendapatkan InputDecoration bergaya ProScan
  InputDecoration _proscanInputDecoration({
    required String labelText,
    String? hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      suffixIcon: suffixIcon,
      labelStyle: TextStyle(color: Colors.grey.shade600),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      
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
    );
  }

  // --- WIDGET HEADER MELENGKUNG (Gaya Manajemen Kegiatan) ---
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
                "Pembelian Paket Data",
                textAlign: canPop ? TextAlign.left : TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (canPop) const SizedBox(width: 48)
          ],
        ),
      ),
    );
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

      // --- ALERT DIALOG (Gaya ProScan) ---
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            "Pembelian Berhasil",
            style: TextStyle(
                color: widget.primaryColor, fontWeight: FontWeight.bold),
          ),
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
              child: Text("Tutup", style: TextStyle(color: widget.primaryColor)),
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
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          // Panggil Header Kustom
          _buildCurvedHeader(context),
          
          // --- FORM INPUT AREA ---
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 20.0,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Masukkan Detail Pembelian",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: widget.primaryColor,
                        ),
                ),
                const SizedBox(height: 16),
                
                // INPUT NOMOR HP
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  decoration: _proscanInputDecoration(
                    labelText: "Nomor HP Tujuan",
                    hintText: "08xxxxxxxxxx",
                    suffixIcon: Icon(Icons.contact_phone, color: widget.accentColor),
                  ),
                ),
                const SizedBox(height: 16),
                
                // DROP DOWN OPERATOR
                DropdownButtonFormField<String>(
                  value: _selectedOperator,
                  style: const TextStyle(color: Colors.black, fontSize: 16),
                  decoration: _proscanInputDecoration(
                    labelText: "Pilih Operator",
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
          
          // --- DAFTAR PAKET DATA (Gaya ProScan) ---
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              itemCount: _dummyPackages.length,
              itemBuilder: (context, index) {
                final pkg = _dummyPackages[index];
                final double price = (pkg['price'] as num).toDouble();

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  color: Colors.white,
                  elevation: 3, // Sedikit lebih jelas
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_kCardRadius),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Kotak Quota (Icon-like)
                        Container(
                          width: 60,
                          height: 60,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: widget.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            pkg['quota'],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: widget.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // Detail Paket
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pkg['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                pkg['detail'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                formatter.format(price),
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: widget.accentColor, // Harga menonjol
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        
                        // Tombol Beli
                        ElevatedButton(
                          onPressed: _submitting
                              ? null
                              : () => _buyPackage(pkg),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0, // Datar
                          ),
                          child: _submitting
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor:
                                        AlwaysStoppedAnimation(Colors.white),
                                  ),
                                )
                              : const Text(
                                  "Beli",
                                  style: TextStyle(
                                      fontSize: 14, fontWeight: FontWeight.w700),
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