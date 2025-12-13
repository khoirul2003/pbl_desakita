import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';

import 'package:frontend/services/api_service.dart';

// Konstanta untuk Gaya ProScan
const double _kBorderRadius = 12.0;
const double _kCardRadius = 16.0;

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
  // String? _dummyCustomerName; // DIHAPUS
  bool _submitting = false;

  final ApiService _apiService = ApiService();

  @override
  void dispose() {
    _meterController.dispose();
    super.dispose();
  }

  // --- FUNGSI CEK PELANGGAN DIHAPUS ---

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
                "Token Listrik",
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
      final totalPaid = amount + fee;

      final newBalance = await _apiService.payPPOB(
        amount: amount,
        productName: 'Token Listrik',
        targetNumber: meter,
        fee: fee,
      );

      final token = _generateDummyToken();

      // --- DIALOG SUKSES (Gaya ProScan + Struk Token) ---
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),

          title: Column(
            children: [
              Icon(Icons.flash_on, color: widget.successColor, size: 48), // Ikon Listrik/Sukses
              const SizedBox(height: 12),
              Text("Pembelian Berhasil",
                  style: TextStyle(
                      color: widget.successColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 20)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              
              // --- DETAIL PELANGGAN ---
              Text("ID Pelanggan:", style: TextStyle(fontWeight: FontWeight.w600, color: widget.primaryColor)),
              Text(meter, style: const TextStyle(fontSize: 14)),
              // if (_dummyCustomerName != null) (DIHAPUS)
              
              const Divider(height: 20),

              // --- KODE TOKEN (FOKUS) ---
              Center(
                child: Column(
                  children: [
                    const Text(
                      "KODE TOKEN:",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      token,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: widget.primaryColor, // Warna token menonjol
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 20),
              
              // --- DETAIL HARGA & SALDO ---
              _buildDetailRow("Nominal", formatter.format(amount)),
              _buildDetailRow("Biaya Admin", formatter.format(fee)),
              _buildDetailRow("Total Dibayar", formatter.format(totalPaid), isTotal: true),
              const Divider(height: 16),
              _buildDetailRow(
                "Saldo Baru",
                newBalance != null ? formatter.format(newBalance) : '-',
                isTotal: true,
              ),

              const SizedBox(height: 12),
              Center(
                child: Text(
                  "Catatan: token ini masih dummy, belum terhubung ke sistem PLN.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // dialog
                  Navigator.of(context).pop(true); // kembali, trigger refresh
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("Tutup", style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
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
  
  // Helper untuk baris detail di dialog
  Widget _buildDetailRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.w500)),
          Text(value,
              style: TextStyle(
                  fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
                  color: isTotal ? widget.primaryColor : Colors.black87)),
        ],
      ),
    );
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

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  // --- HEADER DESKRIPSI ---
                  Text(
                    "Pembelian Token",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith( 
                          fontWeight: FontWeight.w800,
                          color: widget.primaryColor, 
                        ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Masukkan nomor meter dan pilih nominal token listrik.",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 28),


                  // --- INPUT METER & CEK PELANGGAN (MODIFIKASI) ---
                  Container(
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(_kCardRadius),
                      boxShadow: [
                        BoxShadow(
                          color: widget.primaryColor.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _meterController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      decoration: _proscanInputDecoration(
                        labelText: "No. Meter / ID Pelanggan",
                        suffixIcon: Icon(Icons.flash_on, color: widget.accentColor),
                      ),
                    ),
                  ),
                  // --- AREA CEK PELANGGAN DIHAPUS DARI SINI ---


                  // --- PILIH NOMINAL / DENOMINASI ---
                  Text(
                    "Pilih Nominal Token",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: widget.primaryColor,
                        ),
                  ),
                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 12, // Jarak antar chip
                    runSpacing: 12,
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
                        // KUNCI: Styling ChoiceChip ProScan
                        selectedColor: widget.primaryColor, // Warna primary saat terpilih
                        backgroundColor: Colors.white, // Latar belakang putih
                        side: BorderSide(
                          color: selected ? widget.primaryColor : Colors.grey.shade400,
                          width: selected ? 1.5 : 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10), // Sudut membulat
                        ),
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : Colors.black87, // Teks putih saat terpilih
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 40),

                  // --- TOMBOL SUBMIT (Gaya ProScan) ---
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _payToken,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18), // Padding besar
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(_kBorderRadius),
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
                              "Bayar & Dapatkan Token",
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  const Center(
                    child: Text(
                      "Catatan: token & data pelanggan masih simulasi. Backend baru mencatat transaksi & mengurangi saldo.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Colors.grey),
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