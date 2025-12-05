import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/state/auth_provider.dart';
import 'package:dio/dio.dart'; // Diperlukan untuk DioException

// --- DEFINISI WARNA PROSCAN ---
const Color _primaryColor = Color(0xFF0E2F60); // Biru Tua
const Color _backgroundColor = Color(0xFFF5F5F5); // Abu-abu muda untuk Scaffold
const Color _accentColor = Color(0xFF3C486B); // Aksen Biru/Abu
const Color _successColor = Color(0xFF28A745); // Hijau untuk Status Saldo
const Color _dangerColor = Colors.red; // Merah untuk Debit/Pengeluaran

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
    await authProvider.tryAutoLogin();
  }

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  double get totalAmount => (_selectedProduct?.harga ?? 0.0) + _transactionFee;

  void _selectQuickAmount(PulsaProduct product) {
    setState(() {
      _selectedProduct = product;
    });
  }

  // Fungsi Pembayaran
  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate() || _selectedProduct == null) {
      if (_selectedProduct == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Harap pilih nominal pulsa.")),
        );
      }
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
            "Pembelian Pulsa",
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

  // --- WIDGET: CARD RINCIAN PEMBAYARAN ---
  Widget _buildRincianCard(double walletBalance) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Rincian Pembayaran",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: _primaryColor,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
            
            // Isi Rincian
            _buildRincianRow("Nominal Pulsa", _selectedProduct?.harga ?? 0.0),
            _buildRincianRow("Biaya Admin Desapay", _transactionFee, isFee: true),
            const Divider(),
            _buildRincianRow("TOTAL DIBAYAR", totalAmount, isTotal: true),
            
            const SizedBox(height: 20),
            
            // Saldo Saat Ini
            Text(
              "Saldo Anda: ${_rupiahFormatter.format(walletBalance)}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: walletBalance < totalAmount
                    ? Colors.red
                    : _successColor,
              ),
            ),
          ],
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
              color: isTotal ? _primaryColor : (isFee ? Colors.grey[700] : Colors.black87),
            ),
          ),
          Text(
            _rupiahFormatter.format(amount),
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isFee
                  ? Colors.grey
                  : (isTotal
                      ? _primaryColor
                      : Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletBalance =
        context.watch<AuthProvider>().user?.warga?.wallet?.balance ?? 0.0;

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
                    // --- 1. Input Nomor Telepon ---
                    Text(
                      "Nomor Telepon Tujuan",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: _primaryColor,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _numberController,
                      decoration: _inputDecoration.copyWith(
                        labelText: "Contoh: 081234567890",
                        prefixIcon: const Icon(Icons.phone, color: _primaryColor),
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
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: _primaryColor,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10.0,
                      runSpacing: 10.0,
                      children: _pulsaOptions.map((product) {
                        final isSelected = product.id == _selectedProduct?.id;
                        final displayAmount = product.label;
                        
                        // *** PERBAIKAN: Mengganti ActionChip dengan ChoiceChip ***
                        return ChoiceChip(
                          label: Text(displayAmount),
                          // Gunakan properti selected yang tersedia pada ChoiceChip
                          selected: isSelected, 
                          onSelected: (selected) {
                            if (!_isLoading) {
                                _selectQuickAmount(product);
                            }
                          },
                          // Styling ChoiceChip agar sesuai ProScan
                          selectedColor: _primaryColor,
                          disabledColor: Colors.white,
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : _accentColor,
                            fontWeight: FontWeight.bold,
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? _primaryColor
                                : Colors.grey.shade300,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 2,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 30),

                    // --- 3. Konfirmasi & Pembayaran ---
                    // Menggunakan Card Rincian yang sudah disesuaikan
                    _buildRincianCard(walletBalance),

                    const SizedBox(height: 30),

                    ElevatedButton.icon(
                      onPressed: (_isLoading ||
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