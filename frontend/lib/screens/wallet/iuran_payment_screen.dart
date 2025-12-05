import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:math'; 

// Import services and models yang diperlukan (asumsi path ini benar)
import 'package:frontend/services/api_service.dart';
import 'package:frontend/models/wallet_models.dart'; 
import 'package:frontend/models/iuran_model.dart'; // Menggunakan model Iuran Anda

// --- DEFINISI WARNA ---
const Color _primaryColor = Color(0xFF0E2F60); 
const Color _successColor = Color(0xFF28A745); 
const Color _dangerColor = Color(0xFFDC3545); 

// =========================================================================
// MODEL TAGIHAN PERORANGAN (DIBUAT DI FRONTEND UNTUK MENAMPUNG DATA API)
// =========================================================================
class UserTagihan {
  final String id; // ID tagihan unik
  final Iuran iuran; // Jenis iuran yang diambil dari API
  final double jumlah;
  final DateTime jatuhTempo;
  final String status; // 'Belum Lunas'

  UserTagihan({
    required this.id,
    required this.iuran,
    required this.jumlah,
    required this.jatuhTempo,
    required this.status,
  });
}
typedef TagihanIuran = UserTagihan;


class IuranPaymentScreen extends StatefulWidget {
  const IuranPaymentScreen({super.key});

  @override
  State<IuranPaymentScreen> createState() => _IuranPaymentScreenState();
}

class _IuranPaymentScreenState extends State<IuranPaymentScreen> {
  // 1. DAFTAR TAGIHAN DIINISIALISASI SEBAGAI DAFTAR KOSONG
  List<TagihanIuran> _tagihanList = []; 

  bool _isLoading = true;
  String _errorMessage = '';
  Wallet? _userWallet;

  // Tagihan yang dipilih untuk dibayar
  Set<String> _selectedTagihanIds = {}; 

  final NumberFormat _rupiahFormatter = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _fetchTagihanAndWallet(); 
  }

  // Menghitung total jumlah tagihan yang dipilih
  double get _totalPembayaran {
    // Menggunakan tagihan.id, bukan tagihan['id']
    return _tagihanList
        .where((tagihan) => _selectedTagihanIds.contains(tagihan.id))
        .fold(0.0, (sum, tagihan) => sum + tagihan.jumlah);
  }

  // --- LOGIKA PENGAMBILAN DATA (Menggunakan getManajemenIuran yang ada di ApiService) ---
  Future<void> _fetchTagihanAndWallet() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final apiService = context.read<ApiService>();
      
      // 1. Ambil data dompet dari API (Ini yang real dari API)
      final walletData = await apiService.getWalletData(); 
      _userWallet = walletData?['wallet'] as Wallet?;

      // 2. AMBIL JENIS IURAN DARI API (Menggunakan fungsi yang sudah ada di api_service.dart)
      // Asumsi: getManajemenIuran() mengembalikan semua jenis Iuran yang tersedia.
      final List<Iuran> jenisIuran = await apiService.getManajemenIuran(); 
      
      // 3. SIMULASI PEMBUATAN TAGIHAN BELUM LUNAS DARI JENIS IURAN
      final List<UserTagihan> pendingTagihan = [];
      final random = Random();

      for (var iuran in jenisIuran) {
        // Asumsi: Kita hanya buat tagihan belum lunas dari jenis iuran yang ada, 
        // meniru perilaku API getPendingIuran() yang seharusnya.
        // Simulasi bahwa tagihan Kas Warga, Kebersihan, dan Keamanan belum lunas.
        if (iuran.namaIuran != 'Sosial') { 
            pendingTagihan.add(
                UserTagihan(
                    id: 'TGH-${iuran.id}-${random.nextInt(1000)}', // ID Tagihan unik
                    iuran: iuran,
                    jumlah: iuran.jumlah, // Mengambil jumlah dari model Iuran
                    jatuhTempo: DateTime.now().add(const Duration(days: 5)),
                    status: 'Belum Lunas',
                ),
            );
        }
      }

      if (mounted) {
        setState(() {
          // Hanya ambil yang statusnya 'Belum Lunas' (dalam simulasi ini, semua pendingTagihan)
          _tagihanList = pendingTagihan.where((t) => t.status == 'Belum Lunas').toList();
        });
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Gagal memuat saldo atau jenis iuran: ${e.toString()}";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // --- LOGIKA PEMBAYARAN (SIMULASI FRONTEND & REFRESH HOME) ---
  Future<void> _processPayment() async {
    if (_selectedTagihanIds.isEmpty) {
      _showSnackBar("Pilih minimal satu tagihan untuk dibayar.");
      return;
    }

    if (_userWallet == null || _userWallet!.balance < _totalPembayaran) {
      _showSnackBar("Saldo Desapay tidak mencukupi!");
      return;
    }

    // Konfirmasi sebelum pembayaran
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _buildConfirmationDialog(ctx),
    );

    if (confirmed != true) return;

    // Lanjutkan proses pembayaran
    _showSnackBar("Memproses Pembayaran ${_rupiahFormatter.format(_totalPembayaran)}...", duration: const Duration(seconds: 2));

    try {
      // 1. SIMULASI API DELAY
      await Future.delayed(const Duration(seconds: 1)); 
      
      if (mounted) {
        setState(() {
          // 2. SIMULASI PENGURANGAN SALDO LOKAL
          if (_userWallet != null) {
            final double newBalance = _userWallet!.balance - _totalPembayaran;
            _userWallet = Wallet(
              id: _userWallet!.id,
              wargaId: _userWallet!.wargaId, 
              desapayAccountNumber: _userWallet!.desapayAccountNumber, 
              balance: newBalance, // Saldo berkurang!
            );
          }

          // 3. SIMULASI PENGHAPUSAN TAGIHAN LOKAL
          _tagihanList.removeWhere((tagihan) => _selectedTagihanIds.contains(tagihan.id));

          // 4. CLEAR SELECTION
          _selectedTagihanIds.clear(); 
        });
      }
      
      _showSnackBar("Pembayaran Berhasil! Tagihan telah dilunasi.", isSuccess: true);
      
      // 5. Refresh data saldo (local state) dari API
      await _fetchTagihanAndWallet(); 
      
      // 6. Sinyal ke HomeTabWalletContent agar me-refresh riwayat transaksi (WAJIB)
      Navigator.pop(context, true); 
      
    } catch (e) {
      _showSnackBar("Pembayaran Gagal: ${e.toString()}");
    }
  }

  // --- WIDGET HELPER ---
  void _showSnackBar(String message, {Duration duration = const Duration(seconds: 3), bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? _successColor : _dangerColor,
        duration: duration,
      ),
    );
  }

  Widget _buildConfirmationDialog(BuildContext context) {
    return AlertDialog(
      title: const Text("Konfirmasi Pembayaran"),
      content: Text(
        "Anda akan membayar ${_selectedTagihanIds.length} tagihan dengan total ${_rupiahFormatter.format(_totalPembayaran)} menggunakan Desapay. Lanjutkan?",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text("Batal"),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(backgroundColor: _successColor, foregroundColor: Colors.white),
          child: const Text("Bayar Sekarang"),
        ),
      ],
    );
  }

  // --- UI UTAMA ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pembayaran Iuran Desa"),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text("Error: $_errorMessage"))
              : _buildContent(),
      
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

  Widget _buildWalletBalanceCard() {
    final saldo = _userWallet?.balance ?? 0.0;
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _primaryColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Saldo Desapay:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(
            _rupiahFormatter.format(saldo),
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: _primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildTagihanTile(UserTagihan tagihan) {
    final bool isSelected = _selectedTagihanIds.contains(tagihan.id);
    final bool isOverdue = tagihan.jatuhTempo.isBefore(DateTime.now());
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      child: ListTile(
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedTagihanIds.remove(tagihan.id);
            } else {
              _selectedTagihanIds.add(tagihan.id);
            }
          });
        },
        leading: Icon(
          Icons.receipt_long,
          color: isSelected ? _successColor : _primaryColor,
        ),
        title: Text(tagihan.iuran.namaIuran, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tagihan.iuran.deskripsi ?? "Tagihan Iuran"),
            const SizedBox(height: 4),
            Text(
              "Jatuh Tempo: ${DateFormat('dd MMM yyyy').format(tagihan.jatuhTempo)}",
              style: TextStyle(
                color: isOverdue ? _dangerColor : Colors.grey[600],
                fontSize: 12,
                fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _rupiahFormatter.format(tagihan.jumlah),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? _successColor : Colors.black,
              ),
            ),
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
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentButton() {
    final bool isSufficient = (_userWallet?.balance ?? 0.0) >= _totalPembayaran;
    final String buttonText = _selectedTagihanIds.isEmpty
        ? "Pilih Tagihan"
        : isSufficient
            ? "BAYAR ${_rupiahFormatter.format(_totalPembayaran)}"
            : "SALDO KURANG (${_rupiahFormatter.format(_totalPembayaran)})";
            
    final Color buttonColor = isSufficient && _selectedTagihanIds.isNotEmpty
        ? _successColor
        : Colors.grey;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isSufficient && _selectedTagihanIds.isNotEmpty
              ? _processPayment
              : null, // Disable jika saldo kurang atau belum ada tagihan dipilih
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
    );
  }
}