import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/state/auth_provider.dart';
import 'package:dio/dio.dart'; 
import 'package:frontend/screens/placeholder_screen.dart'; // Untuk navigasi sementara

// --- DEFINISI WARNA PROSCAN ---
const Color _primaryColor = Color(0xFF0E2F60); // Biru Tua
const Color _backgroundColor = Color(0xFFF5F5F5); // Abu-abu muda untuk Scaffold
const Color _accentColor = Color(0xFF3C486B); // Aksen Biru/Abu
const Color _successColor = Color(0xFF28A745); // Hijau untuk Status Saldo
const Color _dangerColor = Colors.red; // Merah untuk Kekurangan Saldo

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _targetIdController = TextEditingController(); // ID Akun Tujuan
  final _amountController = TextEditingController();
  
  final double _transactionFee = 500.0; // Biaya admin transfer
  bool _isLoading = false;
  
  // Data dummy: Nama target (untuk simulasi konfirmasi)
  String? _targetName; 

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

  @override
  void dispose() {
    _targetIdController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  // Fungsi: Simulasi cek ID dan ambil nama
  Future<void> _checkTargetId() async {
    final id = _targetIdController.text;
    final authProvider = context.read<AuthProvider>();
    final myDesapayId = authProvider.user?.warga?.wallet?.desapayAccountNumber;

    if (id.isEmpty || id == '0') {
      setState(() { _targetName = null; });
      return;
    }
    
    // Simulasi API call untuk validasi ID
    setState(() { _targetName = 'Memeriksa...'; });
    await Future.delayed(const Duration(milliseconds: 500));
    
    // LOGIKA VALIDASI BARU
    if (id == myDesapayId) {
        // Cek jika ID tujuan sama dengan ID pengguna sendiri
        setState(() { _targetName = "Tidak dapat transfer ke akun sendiri"; });
    } else if (id == '12345' || id.length >= 5) { // Asumsi ID yang valid adalah 5 digit atau lebih
        // Simulasi ID valid (Gunakan ini untuk testing berhasil)
        setState(() { _targetName = "Tujuan Akun ID $id"; }); 
    } else {
        // ID ditemukan tetapi tidak valid 
        setState(() { _targetName = "ID Akun Tidak Ditemukan"; });
    }
  }


  Future<void> _submitTransfer() async {
    // 1. Validasi UI dan Target Name
    if (!_formKey.currentState!.validate() || _targetName == null || 
        _targetName!.contains('Tidak Ditemukan') || _targetName!.contains('akun sendiri')) {
       
        if (_targetName == null || _targetName!.contains('Tidak Ditemukan') || _targetName!.contains('akun sendiri')) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Validasi Tujuan Gagal: ${_targetName ?? 'Harap cek ID'}"), backgroundColor: _dangerColor),
          );
        }
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return;

    final authProvider = context.read<AuthProvider>();
    final apiService = context.read<ApiService>();
    
    // *** FIX AKSES SALDO DENGAN NULL CHECK YANG AMAN ***
    final walletBalance = authProvider.user?.warga?.wallet?.balance ?? 0.0; 
    // ****************************************************
    
    final totalDibayar = amount + _transactionFee;
    final receiverId = _targetIdController.text;

    if (walletBalance < totalDibayar) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Saldo Anda tidak mencukupi."), backgroundColor: Colors.red),
        );
      }
      return;
    }

    setState(() { _isLoading = true; });

    try {
      // *** PANGGIL FUNGSI API YANG SESUNGGUHNYA ***
      final success = await apiService.transferDesapay(
        amount: amount,
        fee: _transactionFee,
        receiverDesapayId: receiverId,
      );
      // ********************************************
      
      if (success && mounted) {
        // Refresh saldo setelah transaksi
        authProvider.tryAutoLogin(); 

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Transfer ${_rupiahFormatter.format(amount)} ke ${_targetName} berhasil!"),
            backgroundColor: _successColor,
            duration: const Duration(seconds: 4),
          ),
        );
        Navigator.of(context).pop(true); // Pop dengan hasil true (perlu refresh)
      } else {
        // Ini jarang dicapai jika API me-rethrow exception, tapi sebagai fallback
        throw Exception("Gagal memproses transfer.");
      }
    } on DioException catch (e) {
      String errorMessage = "Transfer Gagal. Cek Saldo dan Koneksi.";
      
      // Coba ekstrak pesan error dari server
      if (e.response?.data != null && e.response!.data is Map && e.response!.data.containsKey('message')) {
        errorMessage = e.response!.data['message'];
      } else if (e.response?.statusCode == 422) {
        errorMessage = "Gagal Validasi. Pastikan ID dan Saldo mencukupi.";
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: _dangerColor),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Terjadi kesalahan tak terduga: $e"), backgroundColor: _dangerColor),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
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
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
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
          const Text("Transfer Desapay", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // --- WIDGET: CARD RINCIAN PEMBAYARAN ---
  Widget _buildRincianCard(double walletBalance, double amount) {
    final totalDibayar = amount + _transactionFee;
    
    // Gunakan _buildRincianRow yang lebih sesuai dengan detail transfer
    Widget _buildDetailRow(String label, double value, {bool isTotal = false, bool isFee = false}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, color: isTotal ? _primaryColor : (isFee ? Colors.grey[700] : Colors.black87))),
            Text(_rupiahFormatter.format(value), style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, color: isFee ? Colors.grey : (isTotal ? _primaryColor : Colors.black))),
          ],
        ),
      );
    }
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("Konfirmasi Transfer", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: _primaryColor, fontSize: 18)),
            const SizedBox(height: 12),
            
            // Info Penerima (Wah Element)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _backgroundColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "Tujuan: ${_targetName ?? 'Harap masukkan ID'}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _targetName == 'ID Akun Tidak Ditemukan' ? _dangerColor : _accentColor,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Rincian Biaya
            _buildDetailRow("Nominal Transfer", amount),
            _buildDetailRow("Biaya Layanan", _transactionFee, isFee: true),
            const Divider(),
            _buildDetailRow("TOTAL DIBAYAR", totalDibayar, isTotal: true),
            
            const SizedBox(height: 20),
            
            // Saldo Saat Ini
            Text("Saldo Anda: ${_rupiahFormatter.format(walletBalance)}",
              style: TextStyle(fontWeight: FontWeight.bold, color: walletBalance < totalDibayar ? _dangerColor : _successColor)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Pastikan pengambilan saldo menggunakan null check yang aman
    final walletBalance = context.watch<AuthProvider>().user?.warga?.wallet?.balance ?? 0.0;
    final currentAmount = double.tryParse(_amountController.text) ?? 0.0;

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
                    // --- 1. Input ID Akun Tujuan ---
                    Text("ID Akun Tujuan", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: _primaryColor, fontSize: 18)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _targetIdController,
                      decoration: _inputDecoration.copyWith(
                        labelText: "ID Akun (Contoh: 12345)",
                        prefixIcon: const Icon(Icons.person_pin, color: _primaryColor),
                        // Tombol cek ID
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search, color: _primaryColor),
                          onPressed: _checkTargetId,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) => setState(() { _targetName = null; }), // Reset nama saat input berubah
                      validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
                    ),
                    const SizedBox(height: 16),
                    
                    // --- 2. Input Nominal Transfer ---
                    Text("Nominal Transfer", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: _primaryColor, fontSize: 18)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _amountController,
                      decoration: _inputDecoration.copyWith(
                        labelText: "Minimal Rp 1.000",
                        prefixText: "Rp ",
                        prefixStyle: const TextStyle(fontWeight: FontWeight.bold, color: _primaryColor),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) => setState(() {}), // Trigger build untuk update rincian
                      validator: (v) {
                        final amount = double.tryParse(v ?? '0');
                        if (amount == null || amount < 1000) {
                          return "Nominal minimal Rp 1.000";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),

                    // --- 3. Kartu Konfirmasi ---
                    _buildRincianCard(walletBalance, currentAmount),

                    const SizedBox(height: 30),

                    // --- Tombol Bayar ---
                    ElevatedButton.icon(
                      onPressed: (_isLoading || currentAmount <= 0 || _targetName == null || _targetName!.contains('Tidak Ditemukan') || _targetName!.contains('akun sendiri'))
                          ? null
                          : _submitTransfer,
                      icon: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.send),
                      label: Text(_isLoading ? "MEMPROSES TRANSFER..." : "TRANSFER SEKARANG"),
                    ),
                    const SizedBox(height: 10),
                    const Text("Transfer antar akun Desapay dikenakan biaya layanan.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
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