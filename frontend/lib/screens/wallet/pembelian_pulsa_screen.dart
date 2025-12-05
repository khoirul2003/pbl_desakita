import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/state/auth_provider.dart';
import 'package:dio/dio.dart'; // Diperlukan untuk DioException

class PulsaProduct {
  final int id;
  final String label;
  final double harga;

  PulsaProduct({required this.id, required this.label, required this.harga});
}

class PembelianPulsaScreen extends StatefulWidget {
  const PembelianPulsaScreen({super.key});

  @override
  State<PembelianPulsaScreen> createState() => _PembelianPulsaScreenState();
}

class _PembelianPulsaScreenState extends State<PembelianPulsaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _numberController = TextEditingController();
  PulsaProduct? _selectedProduct;
  double _transactionFee = 500.0; // Simulasi biaya admin
  bool _isLoading = false;

  final NumberFormat _rupiahFormatter = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  // Data Pulsa Simulasi (Ganti dengan API Call jika ada)
  final List<PulsaProduct> _pulsaOptions = [
    PulsaProduct(id: 1, label: "Pulsa 10.000", harga: 10000),
    PulsaProduct(id: 2, label: "Pulsa 25.000", harga: 25000),
    PulsaProduct(id: 3, label: "Pulsa 50.000", harga: 50000),
    PulsaProduct(id: 4, label: "Pulsa 100.000", harga: 100000),
  ];

  @override
  void initState() {
    super.initState();
    _checkAndRefreshBalance();
  }

  // Memastikan Saldo Terload
  Future<void> _checkAndRefreshBalance() async {
    final authProvider = context.read<AuthProvider>();
    // Memuat ulang data user/wallet dari server
    await authProvider.tryAutoLogin();
  }

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  double get totalAmount => (_selectedProduct?.harga ?? 0.0) + _transactionFee;

  // Fungsi Pembayaran
  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate() || _selectedProduct == null) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final apiService = context.read<ApiService>();
    final walletBalance = authProvider.user?.warga?.wallet?.balance ?? 0.0;

    if (walletBalance < totalAmount) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Saldo Anda tidak mencukupi."),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await apiService.payPPOB(
        amount: _selectedProduct!.harga,
        fee: _transactionFee,
        productName: _selectedProduct!.label,
        targetNumber: _numberController.text,
      );

      if (success && mounted) {
        // [1] Memaksa refresh data di provider
        authProvider.tryAutoLogin();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Pembelian Pulsa Berhasil! Saldo Desapay dikurangi."),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );

        // [2] PENTING: Pop dengan hasil 'true' agar Home Screen me-refresh tampilan
        Navigator.of(context).pop(true);
      } else {
        throw Exception(
          "Gagal memproses pembayaran. Saldo tidak cukup atau NIK/Token salah.",
        );
      }
    } catch (e) {
      String errorMessage = "Pembayaran Gagal. Cek Saldo dan Koneksi.";
      if (e is DioException && e.response?.statusCode == 422) {
        errorMessage = e.response!.data['message'] ?? errorMessage;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
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

  @override
  Widget build(BuildContext context) {
    // Ambil saldo saat ini dari provider
    final walletBalance =
        context.watch<AuthProvider>().user?.warga?.wallet?.balance ?? 0.0;

    return Scaffold(
      appBar: AppBar(title: const Text("Pembelian Pulsa")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- 1. Input Nomor Telepon ---
              Text(
                "Nomor Telepon Tujuan",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _numberController,
                decoration: const InputDecoration(
                  labelText: "Contoh: 081234567890",
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) =>
                    v!.length < 9 ? "Masukkan nomor telepon yang valid." : null,
              ),
              const SizedBox(height: 30),

              // --- 2. Pilihan Nominal ---
              Text(
                "Pilih Nominal Pulsa",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10.0,
                runSpacing: 10.0,
                children: _pulsaOptions.map((product) {
                  final isSelected = product.id == _selectedProduct?.id;
                  return ChoiceChip(
                    label: Text(product.label),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedProduct = selected ? product : null;
                      });
                    },
                    selectedColor: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                    elevation: 1,
                  );
                }).toList(),
              ),
              const SizedBox(height: 30),

              // --- 3. Konfirmasi & Pembayaran ---
              Text(
                "Rincian Pembayaran",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),

              _buildRincianRow("Nominal Pulsa", _selectedProduct?.harga ?? 0.0),
              _buildRincianRow(
                "Biaya Admin Desapay",
                _transactionFee,
                isFee: true,
              ),
              const Divider(),
              _buildRincianRow("TOTAL DIBAYAR", totalAmount, isTotal: true),

              const SizedBox(height: 20),

              Text(
                "Saldo Anda: ${_rupiahFormatter.format(walletBalance)}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: walletBalance < totalAmount
                      ? Colors.red
                      : Colors.green.shade700,
                ),
              ),
              const SizedBox(height: 30),

              ElevatedButton.icon(
                onPressed:
                    (_isLoading ||
                        _selectedProduct == null ||
                        walletBalance < totalAmount)
                    ? null
                    : _submitPayment,
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
                label: Text(
                  _isLoading ? "MEMPROSES..." : "BAYAR DENGAN DESAPAY",
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRincianRow(
    String label,
    double amount, {
    bool isTotal = false,
    bool isFee = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            _rupiahFormatter.format(amount),
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isFee
                  ? Colors.grey
                  : (isTotal
                        ? Theme.of(context).colorScheme.primary
                        : Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}
