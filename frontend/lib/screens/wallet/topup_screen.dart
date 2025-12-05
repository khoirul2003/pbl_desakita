import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

// Sesuaikan path ini
import 'package:frontend/services/api_service.dart';

// --- DEFINISI WARNA PROSCAN ---
const Color _primaryColor = Color(0xFF0E2F60); // Biru Tua
const Color _backgroundColor = Color(0xFFF5F5F5); // Abu-abu muda untuk Scaffold
const Color _accentColor = Color(0xFF3C486B); // Aksen Biru/Abu

class TopUpScreen extends StatefulWidget {
  const TopUpScreen({super.key});

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  bool _isLoading = false;

  // Custom Input Decoration (Gaya ProScan)
  final InputDecoration _inputDecoration = InputDecoration(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    labelStyle: const TextStyle(color: _accentColor),
    prefixStyle: const TextStyle(fontWeight: FontWeight.bold, color: _primaryColor),
  );


  // Daftar nominal cepat yang bisa diklik
  final List<double> _quickAmounts = [
    10000,
    20000,
    50000,
    100000,
    200000,
    500000,
  ];
  
  // Formatter untuk menampilkan Rupiah pada chip
  final NumberFormat _rupiahFormatter = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp',
    decimalDigits: 0,
  );


  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _selectQuickAmount(double amount) {
    setState(() {
      _amountController.text = amount.toStringAsFixed(0); // Hapus desimal
    });
  }

  Future<void> _submitTopUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return;

    setState(() {
      _isLoading = true;
    });

    final apiService = context.read<ApiService>();

    try {
      final newBalance = await apiService.topUpWallet(amount);

      if (newBalance != null && mounted) {
        // Tampilkan notifikasi sukses
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Top Up Rp ${amount.toStringAsFixed(0)} berhasil! Saldo baru: Rp ${newBalance.toStringAsFixed(0)}",
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        // Kembali ke layar sebelumnya (Home/Profile)
        Navigator.of(
          context,
        ).pop(true); // Pop dengan hasil true (perlu refresh)
      } else {
        throw Exception("Gagal mendapatkan saldo baru.");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Top Up Gagal: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // --- WIDGET: CUSTOM HEADER PROSCAN ---
  Widget _buildCustomHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      decoration: const BoxDecoration(
        color: _primaryColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          const Text(
            "Isi Saldo Desapay (Demo)",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Column(
        children: [
          _buildCustomHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "Masukkan Nominal Top Up",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: _primaryColor,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _amountController,
                      decoration: _inputDecoration.copyWith(
                        labelText: "Nominal",
                        prefixText: "Rp ",
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        final amount = double.tryParse(value ?? '');
                        if (amount == null || amount < 1000) {
                          return "Nominal minimal Rp 1.000";
                        }
                        if (amount > 1000000) {
                          return "Nominal maksimal Rp 1.000.000 (Demo)";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // --- Pilihan Cepat ---
                    Text(
                      "Pilihan Cepat",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: _accentColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: _quickAmounts.map((amount) {
                        final isSelected = _amountController.text == amount.toStringAsFixed(0);
                        final displayAmount = _rupiahFormatter.format(amount);

                        return ActionChip(
                          label: Text(displayAmount),
                          onPressed: _isLoading
                              ? null
                              : () => _selectQuickAmount(amount),
                          backgroundColor: isSelected
                              ? _primaryColor
                              : Colors.white,
                          side: BorderSide(
                            color: isSelected
                                ? _primaryColor
                                : Colors.grey.shade300,
                            width: 1.5,
                          ),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : _accentColor,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _submitTopUp,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.payment),
                      label: Text(_isLoading ? "MEMPROSES..." : "LANJUTKAN TOP UP"),
                      // Menggunakan style ElevatedButton global dari MaterialApp
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Catatan: Ini adalah simulasi Top Up. Tidak ada integrasi Payment Gateway nyata.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}