import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';

import 'package:frontend/services/api_service.dart'; 

// Konstanta untuk BorderRadius (sesuai permintaan 12dp)
const double _kBorderRadius = 12.0;
const double _kCardRadius = 16.0;

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
    final NumberFormat inputFormatter = NumberFormat.decimalPattern('id_ID');
    final String formattedAmount = inputFormatter.format(amount);
    
    _amountController.text = formattedAmount;
    
    _amountController.selection = TextSelection.fromPosition(
      TextPosition(offset: _amountController.text.length),
    );
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

      // --- Dialog Sukses (Gaya ProScan) ---
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
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
                "Top Up Desapay",
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
          // Panggil header kustom
          _buildCurvedHeader(context), 
          
          // Konten Utama
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0), 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  // --- AREA DESKRIPSI & JUDUL ---
                  Text(
                    "Top Up Saldo",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith( 
                          fontWeight: FontWeight.w800,
                          color: widget.primaryColor, 
                        ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Pilih atau masukkan nominal yang Anda inginkan.",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 28),

                  // --- CONTAINER INPUT UTAMA (Card-like) ---
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(_kCardRadius),
                      boxShadow: [
                        BoxShadow(
                          color: widget.primaryColor.withOpacity(0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "Masukkan Nominal Top Up",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // KUNCI PERBAIKAN: Input Field Menonjol dengan Centering Rp
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              "Rp ",
                              style: TextStyle(
                                fontSize: 38,
                                fontWeight: FontWeight.w900,
                                color: widget.primaryColor,
                              ),
                            ),
                            // *** PERUBAHAN DI SINI: Mengurangi lebar SizedBox menjadi 45% ***
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.45, 
                              child: TextField(
                                controller: _amountController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.start, 
                                style: TextStyle(
                                  fontSize: 38,
                                  fontWeight: FontWeight.w900,
                                  color: widget.primaryColor,
                                ),
                                decoration: InputDecoration(
                                  hintText: "0",
                                  hintStyle: TextStyle(
                                    fontSize: 38,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.grey.shade300,
                                  ),
                                  border: InputBorder.none, 
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                  
                  // --- OPSI CEPAT (QUICK AMOUNTS) ---
                  Text(
                    "Pilih Opsi Cepat",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: widget.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _quickAmounts.map((e) {
                      return OutlinedButton(
                        onPressed: () => _fillQuickAmount(e),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: widget.primaryColor,
                          side: BorderSide(
                              color: widget.primaryColor.withOpacity(0.8)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 12),
                        ),
                        child: Text(
                          formatter.format(e),
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
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
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(_kBorderRadius),
                        ),
                        elevation: 5,
                        shadowColor: widget.primaryColor.withOpacity(0.5),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              "Top Up Sekarang",
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