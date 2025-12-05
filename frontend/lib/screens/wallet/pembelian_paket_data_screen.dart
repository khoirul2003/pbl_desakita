import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/state/auth_provider.dart';
import 'package:dio/dio.dart';

// --- DEFINISI WARNA PROSCAN ---
const Color _primaryColor = Color(0xFF0E2F60);
const Color _backgroundColor = Color(0xFFF5F5F5);
const Color _accentColor = Color(0xFF3C486B);
const Color _successColor = Color(0xFF28A745);
const Color _dangerColor = Colors.red;

class PaketDataProduct {
  final int id;
  final String providerName;
  final String label;
  final double harga;
  PaketDataProduct({required this.id, required this.providerName, required this.label, required this.harga});
}

class PembelianPaketDataScreen extends StatefulWidget {
  const PembelianPaketDataScreen({super.key});
  @override
  State<PembelianPaketDataScreen> createState() => _PembelianPaketDataScreenState();
}

class _PembelianPaketDataScreenState extends State<PembelianPaketDataScreen> {
  final _formKey = GlobalKey<FormState>();
  final _numberController = TextEditingController();
  PaketDataProduct? _selectedProduct;
  final double _transactionFee = 150990.0;
  bool _isLoading = false;

  final NumberFormat _rupiahFormatter = NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0);
  final InputDecoration _inputDecoration = InputDecoration(
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    labelStyle: const TextStyle(color: _accentColor),
    prefixStyle: const TextStyle(fontWeight: FontWeight.bold, color: _primaryColor),
  );

  final List<PaketDataProduct> _paketDataOptions = [
    // Telkomsel
    PaketDataProduct(id: 1, providerName: "Telkomsel", label: "3 GB / 3 Hari", harga: 20000),
    PaketDataProduct(id: 2, providerName: "Telkomsel", label: "5 GB / 7 Hari", harga: 30000),
    PaketDataProduct(id: 3, providerName: "Telkomsel", label: "15 GB / 30 Hari", harga: 65000),
    PaketDataProduct(id: 4, providerName: "Telkomsel", label: "30 GB / 30 Hari", harga: 99000),
    // Indosat
    PaketDataProduct(id: 5, providerName: "Indosat", label: "6 GB Freedom", harga: 35000),
    PaketDataProduct(id: 6, providerName: "Indosat", label: "20 GB Freedom", harga: 75000),
    PaketDataProduct(id: 7, providerName: "Indosat", label: "Unlimited Jumbo", harga: 130000),
    // XL
    PaketDataProduct(id: 8, providerName: "XL", label: "1 GB Harian", harga: 15000),
    PaketDataProduct(id: 9, providerName: "XL", label: "10 GB Xtra Combo", harga: 50000),
    PaketDataProduct(id: 10, providerName: "XL", label: "30 GB Kuota Utama", harga: 120000),
    // Tri (3)
    PaketDataProduct(id: 11, providerName: "Tri", label: "Always On 3 GB", harga: 18000),
    PaketDataProduct(id: 12, providerName: "Tri", label: "Kuota++ 10 GB", harga: 35000),
    PaketDataProduct(id: 13, providerName: "Tri", label: "Unlimited 30 Hari", harga: 95000),
    // Smartfren
    PaketDataProduct(id: 14, providerName: "Smartfren", label: "5 GB Volume", harga: 25000),
    PaketDataProduct(id: 15, providerName: "Smartfren", label: "15 GB Nonstop", harga: 70000),
    PaketDataProduct(id: 16, providerName: "Smartfren", label: "Kuota Malam Unlimited", harga: 50000),
  ];

  @override
  void initState() {
    super.initState();
    context.read<AuthProvider>().tryAutoLogin();
  }

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  double get totalAmount => (_selectedProduct?.harga ?? 0.0) + _transactionFee;

  void _selectQuickAmount(PaketDataProduct product) => setState(() { _selectedProduct = product; });

  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate() || _selectedProduct == null) {
      if (_selectedProduct == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Harap pilih paket data.")));
      }
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final apiService = context.read<ApiService>();
    final walletBalance = authProvider.user?.warga?.wallet?.balance ?? 0.0;

    if (walletBalance < totalAmount) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Saldo Anda tidak mencukupi."), backgroundColor: Colors.red));
      }
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final success = await apiService.payPPOB(
        amount: _selectedProduct!.harga,
        fee: _transactionFee,
        productName: _selectedProduct!.label,
        targetNumber: _numberController.text,
      );

      if (success && mounted) {
        authProvider.tryAutoLogin();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Pembelian Paket Data (${_selectedProduct!.label}) Berhasil!"), backgroundColor: Colors.green, duration: const Duration(seconds: 4)),
        );
        Navigator.of(context).pop(true);
      } else {
        throw Exception("Gagal memproses pembayaran. Saldo tidak cukup atau nomor salah.");
      }
    } catch (e) {
      String errorMessage = "Pembayaran Gagal. Cek Saldo dan Koneksi.";
      if (e is DioException && e.response?.statusCode == 422) {
        errorMessage = e.response!.data['message'] ?? errorMessage;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  Widget _buildCustomHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8, left: 16, right: 16, bottom: 16,
      ),
      decoration: const BoxDecoration(
        color: _primaryColor,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
          const SizedBox(width: 8),
          const Text("Pembelian Paket Data", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildRincianCard(double walletBalance) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("Rincian Pembayaran", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: _primaryColor, fontSize: 18)),
            const SizedBox(height: 12),
            _buildRincianRow("Nominal Paket", _selectedProduct?.harga ?? 0.0),
            _buildRincianRow("Biaya Admin Desapay", _transactionFee, isFee: true),
            const Divider(),
            _buildRincianRow("TOTAL DIBAYAR", totalAmount, isTotal: true),
            const SizedBox(height: 20),
            Text("Saldo Anda: ${_rupiahFormatter.format(walletBalance)}",
              style: TextStyle(fontWeight: FontWeight.bold, color: walletBalance < totalAmount ? Colors.red : _successColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildRincianRow(String label, double amount, {bool isTotal = false, bool isFee = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, color: isTotal ? _primaryColor : (isFee ? Colors.grey[700] : Colors.black87))),
          Text(_rupiahFormatter.format(amount),
            style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, color: isFee ? Colors.grey : (isTotal ? _primaryColor : Colors.black))),
        ],
      ),
    );
  }

  Widget _buildPaketDataListView() {
    final Map<String, List<PaketDataProduct>> groupedProducts = {};
    for (var product in _paketDataOptions) {
      groupedProducts.putIfAbsent(product.providerName, () => []).add(product);
    }
    final List<String> providers = groupedProducts.keys.toList();

    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: providers.length,
        itemBuilder: (context, index) {
          final products = groupedProducts[providers[index]]!;
          return _buildProviderColumn(providers[index], products);
        },
      ),
    );
  }
  
  Widget _buildProviderColumn(String provider, List<PaketDataProduct> products) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: _primaryColor.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(provider, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _primaryColor)),
          const Divider(height: 6), // DIRAPATKAN
          Expanded( 
            child: ListView.builder(
              itemCount: products.length,
              physics: const ClampingScrollPhysics(), 
              itemBuilder: (context, index) {
                final product = products[index];
                final isSelected = product.id == _selectedProduct?.id;
                
                return InkWell(
                  onTap: _isLoading ? null : () => _selectQuickAmount(product),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4), // DIRAPATKAN
                    margin: const EdgeInsets.only(bottom: 2), // DIRAPATKAN
                    decoration: BoxDecoration(
                      color: isSelected ? _primaryColor.withOpacity(0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected ? Border.all(color: _primaryColor, width: 1.5) : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(product.label, style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: _accentColor)),
                        Text(_rupiahFormatter.format(product.harga), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
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


  @override
  Widget build(BuildContext context) {
    final walletBalance = context.watch<AuthProvider>().user?.warga?.wallet?.balance ?? 0.0;

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
                    Text("Nomor Telepon Tujuan", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: _primaryColor, fontSize: 18)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _numberController,
                      decoration: _inputDecoration.copyWith(labelText: "Contoh: 081234567890", prefixIcon: const Icon(Icons.phone, color: _primaryColor)),
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) => v!.length < 9 ? "Masukkan nomor telepon yang valid." : null,
                    ),
                    const SizedBox(height: 30),

                    // --- 2. Pilihan Nominal (HORIZONTAL LISTVIEW) ---
                    Text("Pilih Paket Data", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: _primaryColor, fontSize: 18)),
                    const SizedBox(height: 12),
                    
                    _buildPaketDataListView(), 
                    
                    const SizedBox(height: 30),

                    // --- 3. Konfirmasi & Pembayaran ---
                    _buildRincianCard(walletBalance),

                    const SizedBox(height: 30),

                    ElevatedButton.icon(
                      onPressed: (_isLoading || _selectedProduct == null || walletBalance < totalAmount) ? null : _submitPayment,
                      icon: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.payment),
                      label: Text(_isLoading ? "MEMPROSES..." : "BAYAR DENGAN DESAPAY"),
                    ),
                    const SizedBox(height: 10),
                    const Text("Catatan: Ini adalah simulasi PPOB. Tidak ada integrasi Payment Gateway nyata.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
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