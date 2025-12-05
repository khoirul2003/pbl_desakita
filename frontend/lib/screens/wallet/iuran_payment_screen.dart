import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:math'; 
// Import Dio untuk menggunakan DioException
import 'package:dio/dio.dart'; 

// Import services and models yang diperlukan (asumsi path ini benar)
import 'package:frontend/services/api_service.dart';
import 'package:frontend/models/wallet_models.dart'; 
import 'package:frontend/models/iuran_model.dart'; // Menggunakan model Iuran Anda
import 'package:frontend/state/auth_provider.dart';

// --- DEFINISI WARNA PROSCAN ---
const Color _primaryColor = Color(0xFF0E2F60); 
const Color _backgroundColor = Color(0xFFF5F5F5); 
const Color _accentColor = Color(0xFF3C486B); 
const Color _successColor = Color(0xFF28A745); 
const Color _dangerColor = Color(0xFFDC3545); 

// =========================================================================
// MODEL TAGIHAN PERORANGAN
// =========================================================================
class UserTagihan {
  final String id; 
  final Iuran iuran; 
  final double jumlah;
  final DateTime jatuhTempo;
  final String status; 

  UserTagihan({
    required this.id, required this.iuran, required this.jumlah, 
    required this.jatuhTempo, required this.status,
  });
}
typedef TagihanIuran = UserTagihan;


class IuranPaymentScreen extends StatefulWidget {
  const IuranPaymentScreen({super.key});

  @override
  State<IuranPaymentScreen> createState() => _IuranPaymentScreenState();
}

class _IuranPaymentScreenState extends State<IuranPaymentScreen> {
  List<TagihanIuran> _tagihanList = []; 
  bool _isLoading = true;
  String _errorMessage = '';
  Wallet? _userWallet;

  Set<String> _selectedTagihanIds = {}; 

  final NumberFormat _rupiahFormatter = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp',
    decimalDigits: 0,
  );
  
  Color get _successColorShade => Color.lerp(_successColor, Colors.black, 0.2) ?? _successColor;


  @override
  void initState() {
    super.initState();
    _fetchTagihanAndWallet(); 
  }

  // Menghitung total jumlah tagihan yang dipilih
  double get _totalPembayaran {
    return _tagihanList
        .where((tagihan) => _selectedTagihanIds.contains(tagihan.id))
        .fold(0.0, (sum, tagihan) => sum + tagihan.jumlah);
  }

  // --- LOGIKA PENGAMBILAN DATA ---
  Future<void> _fetchTagihanAndWallet() async {
    setState(() { _isLoading = true; _errorMessage = ''; });

    try {
      final apiService = context.read<ApiService>();
      
      final walletData = await apiService.getWalletData(); 
      _userWallet = walletData?['wallet'] as Wallet?;

      final List<Iuran> jenisIuran = await apiService.getManajemenIuran(); 
      
      final List<UserTagihan> pendingTagihan = [];
      final random = Random();

      for (var iuran in jenisIuran) {
        if (iuran.namaIuran != 'Sosial' && iuran.namaIuran != 'Sampah') { 
            pendingTagihan.add(
                UserTagihan(
                    id: 'TGH-${iuran.id}-${random.nextInt(1000)}',
                    iuran: iuran,
                    jumlah: iuran.jumlah,
                    jatuhTempo: DateTime.now().subtract(const Duration(days: 10)),
                    status: 'Belum Lunas',
                ),
            );
        }
      }

      if (mounted) {
        setState(() {
          _tagihanList = pendingTagihan.where((t) => t.status == 'Belum Lunas').toList();
        });
      }

    } catch (e) {
      if (mounted) {
        setState(() { _errorMessage = "Gagal memuat saldo atau jenis iuran: ${e.toString()}"; });
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  // --- LOGIKA PEMBAYARAN ---
  Future<void> _processPayment() async {
    if (_selectedTagihanIds.isEmpty) {
      _showSnackBar("Pilih minimal satu tagihan untuk dibayar.");
      return;
    }

    if (_userWallet == null || _userWallet!.balance < _totalPembayaran) {
      _showSnackBar("Saldo Desapay tidak mencukupi!");
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _buildConfirmationDialog(ctx),
    );

    if (confirmed != true) return;

    setState(() { _isLoading = true; });
    final authProvider = context.read<AuthProvider>();
    final apiService = context.read<ApiService>();


    try {
      // 1. PANGGIL API PEMBAYARAN IURAN SEBENARNYA (Asumsi ada endpoint di ApiService)
      // Kita asumsikan ini akan memotong saldo dan mencatat transaksi di server
      // final success = await apiService.payIuran(
      //   totalAmount: _totalPembayaran,
      //   tagihanIds: _selectedTagihanIds.toList(),
      // );
      
      // --- SIMULASI SUKSES KARENA LACK OF ENDPOINT ---
      await Future.delayed(const Duration(milliseconds: 500)); 
      final success = true; 
      // ---------------------------------------------
      
      if (success && mounted) {
        
        // 2. Refresh SALDO dan Riwayat Transaksi (WAJIB)
        await authProvider.tryAutoLogin(); 
        
        // 3. Update UI Lokal (Hapus Tagihan)
        if (mounted) {
          setState(() {
            // Logika untuk simulasi update saldo lokal:
             if (_userWallet != null) {
              final double newBalance = _userWallet!.balance - _totalPembayaran;
              _userWallet = Wallet(
                id: _userWallet!.id,
                wargaId: _userWallet!.wargaId, 
                desapayAccountNumber: _userWallet!.desapayAccountNumber, 
                balance: newBalance,
              );
            }
            _tagihanList.removeWhere((tagihan) => _selectedTagihanIds.contains(tagihan.id));
            _selectedTagihanIds.clear(); 
          });
        }
        
        _showSnackBar("Pembayaran Berhasil! Tagihan telah dilunasi.", isSuccess: true);
        
        // 4. Sinyal ke HomeTabWalletContent agar me-refresh riwayat transaksi
        Navigator.pop(context, true); 
        
      } else {
        throw Exception("Pembayaran gagal, silakan coba lagi.");
      }
      
    } on DioException catch (e) { // FIX: DioException sekarang dikenali
        String errorMessage = "Pembayaran Gagal. Cek Saldo dan Koneksi.";
        if (e.response?.data != null && e.response!.data.containsKey('message')) {
             errorMessage = e.response!.data['message'];
        }
       _showSnackBar(errorMessage);
       
    } catch (e) {
      _showSnackBar("Pembayaran Gagal: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  // --- WIDGET HELPER ---
  void _showSnackBar(String message, {Duration duration = const Duration(seconds: 3), bool isSuccess = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isSuccess ? _successColor : _dangerColor,
          duration: duration,
        ),
      );
    }
  }
  
  // Custom Header ProScan
  Widget _buildCustomHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8, left: 16, right: 16, bottom: 16,
      ),
      decoration: const BoxDecoration(
        color: _primaryColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white), 
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          const Text("Pembayaran Iuran", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // Kartu Saldo Desapay
  Widget _buildWalletBalanceCard() {
    final saldo = _userWallet?.balance ?? 0.0;
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: _primaryColor.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Saldo Desapay:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _primaryColor)),
          Text(
            _rupiahFormatter.format(saldo),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: _successColor),
          ),
        ],
      ),
    );
  }

  // Tile Tagihan Iuran
  Widget _buildTagihanTile(UserTagihan tagihan) {
    final bool isSelected = _selectedTagihanIds.contains(tagihan.id);
    final bool isOverdue = tagihan.jatuhTempo.isBefore(DateTime.now());
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedTagihanIds.remove(tagihan.id);
            } else {
              _selectedTagihanIds.add(tagihan.id);
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Checkbox / Status Icon
              Checkbox(
                value: isSelected,
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      if (val) {
                        _selectedTagihanIds.add(tagihan.id);
                      } else {
                        _selectedTagihanIds.remove(tagihan.id);
                      }
                    });
                  }
                },
                activeColor: _successColor,
              ),
              const SizedBox(width: 8),
              
              // Detail Tagihan
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tagihan.iuran.namaIuran, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: _accentColor)),
                    const SizedBox(height: 4),
                    Text(
                      tagihan.iuran.deskripsi ?? "Tagihan Iuran",
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Jatuh Tempo: ${DateFormat('dd MMM yyyy').format(tagihan.jatuhTempo)}",
                      style: TextStyle(
                        color: isOverdue ? _dangerColor : _successColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Jumlah
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  _rupiahFormatter.format(tagihan.jumlah),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isSelected ? _successColor : Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Tombol Pembayaran (Bottom Bar)
  Widget _buildPaymentButton() {
    final bool isSufficient = (_userWallet?.balance ?? 0.0) >= _totalPembayaran;
    final bool canPay = isSufficient && _selectedTagihanIds.isNotEmpty && !_isLoading;
    
    final String buttonText = _selectedTagihanIds.isEmpty
        ? "Pilih Tagihan"
        : isSufficient
            ? "BAYAR ${_rupiahFormatter.format(_totalPembayaran)}"
            : "SALDO KURANG (${_rupiahFormatter.format(_totalPembayaran)})";
            
    final Color buttonColor = canPay ? _successColor : Colors.grey;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: canPay ? _processPayment : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              buttonText,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmationDialog(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // Sudut membulat
      title: Text(
        "Konfirmasi Pembayaran",
        style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Anda akan melunasi tagihan berikut:", style: TextStyle(fontSize: 16)),
          const SizedBox(height: 10),
          
          // Ringkasan Tagihan yang dipilih
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _backgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _primaryColor.withOpacity(0.1)),
            ),
            child: Text(
              "${_selectedTagihanIds.length} Tagihan Iuran",
              style: const TextStyle(fontWeight: FontWeight.bold, color: _primaryColor),
            ),
          ),
          
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: const Text("Total Pembayaran:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500))),
              Expanded(
                child: Text(
                  _rupiahFormatter.format(_totalPembayaran),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _successColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text("Batal", style: TextStyle(color: _accentColor)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: _successColor, 
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text("Bayar Sekarang", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }


  // --- UI UTAMA ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      // AppBar sudah diganti dengan Custom Header
      body: Column(
        children: [
          _buildCustomHeader(context),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: _primaryColor))
                : _errorMessage.isNotEmpty
                      ? Center(child: Text("Error: $_errorMessage"))
                      : _buildContent(),
          ),
        ],
      ),
      
      // Tombol Bayar di bagian bawah
      bottomNavigationBar: _tagihanList.isNotEmpty ? _buildPaymentButton() : null,
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Saldo Wallet (Tampil di atas daftar tagihan)
        _buildWalletBalanceCard(),
        
        // Daftar Tagihan
        Expanded(
          child: _tagihanList.isEmpty
              ? Center(
                  child: Text(
                    "Semua tagihan Iuran sudah lunas! 👍",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                )
              : ListView.builder(
                  // Padding horizontal sudah diatur di _buildTagihanTile margin
                  padding: const EdgeInsets.only(top: 8, bottom: 80),
                  itemCount: _tagihanList.length,
                  itemBuilder: (context, index) {
                    final tagihan = _tagihanList[index];
                    return _buildTagihanTile(tagihan);
                  },
                ),
        ),
      ],
    );
  }
}