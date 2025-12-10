import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:frontend/services/api_service.dart';

// Konstanta untuk Gaya ProScan
const double _kBorderRadius = 12.0;

class DesaPayPulsaScreen extends StatefulWidget {
  final Color primaryColor; // Navy Blue
  final Color accentColor; // Warna Aksen (mis. Biru Cerah)

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

      // --- ALERT DIALOG (Gaya ProScan) ---
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            "Pembelian Pulsa Berhasil",
            style: TextStyle(
                color: widget.primaryColor, fontWeight: FontWeight.bold),
          ),
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
              child: Text("Tutup", style: TextStyle(color: widget.primaryColor)),
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


  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Pembelian Pulsa"),
        backgroundColor: widget.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0), // Padding lebih besar
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER DESKRIPSI (Gaya ProScan) ---
            Text(
              "Beli Pulsa & Paket Data.",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800, // Sangat tebal
                    color: widget.primaryColor,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              "Isi pulsa menggunakan saldo Desapay (demo).",
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 30),

            // --- INPUT NOMOR HP ---
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(fontWeight: FontWeight.w600),
              decoration: _proscanInputDecoration(
                labelText: "Nomor HP Tujuan",
                hintText: "08xxxxxxxxxx",
                // Tambahkan ikon opsional untuk kontak
                suffixIcon: Icon(Icons.contact_phone, color: widget.accentColor),
              ),
            ),
            const SizedBox(height: 20),

            // --- DROP DOWN OPERATOR ---
            DropdownButtonFormField<String>(
              value: _selectedOperator,
              style: const TextStyle(
                  color: Colors.black, fontSize: 16), // Penting agar teks tidak hilang
              decoration: _proscanInputDecoration(
                labelText: "Pilih Operator",
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
            const SizedBox(height: 30),

            // --- PILIH NOMINAL / DENOMINASI ---
            Text(
              "Pilih Nominal Pulsa",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: widget.primaryColor,
                  ),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 10, // Jarak antar chip
              runSpacing: 10,
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
                  // KUNCI: Styling ChoiceChip ProScan
                  selectedColor: widget.primaryColor, // Warna primary saat terpilih
                  backgroundColor: Colors.grey.shade100,
                  side: BorderSide(
                    color: selected ? widget.primaryColor : Colors.grey.shade300,
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
                onPressed: _submitting ? null : _submitPurchase,
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
                        "Bayar Sekarang (Demo)",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 12),
            const Center(
              child: Text(
                "Catatan: hanya simulasi. Integrasikan dengan API operator / payment gateway untuk transaksi nyata.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}