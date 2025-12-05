import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/models/wallet_models.dart';
import 'package:frontend/state/auth_provider.dart';

// --- DEFINISI WARNA PROSCAN ---
const Color _primaryColor = Color(0xFF0E2F60); // Biru Tua
const Color _backgroundColor = Color(0xFFF5F5F5);
const Color _successColor = Color(0xFF28A745);
const Color _dangerColor = Colors.red;
const Color _accentColor = Color(0xFF3C486B); 
const Color _tabIndicatorColor = Color(0xFF90a4ae); // Warna abu-abu untuk tab pasif

class RiwayatTransaksiScreen extends StatefulWidget {
  const RiwayatTransaksiScreen({super.key});

  @override
  State<RiwayatTransaksiScreen> createState() => _RiwayatTransaksiScreenState();
}

class _RiwayatTransaksiScreenState extends State<RiwayatTransaksiScreen> {
  List<Transaction> _allTransactions = [];
  bool _isLoading = true;
  String _errorMessage = '';
  
  // *** STATE UNTUK FILTER ***
  String _currentFilter = 'ALL'; // 'ALL', 'INCOMING', 'OUTBOUND' 

  final NumberFormat _rupiahFormatter = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _fetchFullHistory();
  }

  Future<void> _fetchFullHistory() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final apiService = context.read<ApiService>();

    try {
      final data = await apiService.getWalletData(); 
      if (data != null && mounted) {
        List<Transaction> transactions = (data['transactions'] as List<Transaction>);
        transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        setState(() {
          // Menyimpan semua data untuk filtering di sisi klien
          _allTransactions = transactions; 
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Gagal memuat riwayat: ${e.toString()}";
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
  
  // Helper function untuk Card Wrapper dengan Shadow ProScan
  Widget _buildCardWrapper({required Widget child, EdgeInsets padding = const EdgeInsets.all(16)}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6), 
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12), 
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6, 
            offset: const Offset(0, 3),
          )
        ],
      ),
      padding: padding,
      child: child,
    );
  }

  // --- LOGIKA PERHITUNGAN SALDO (SIMULASI UNTUK USER WALLET) ---
  Map<String, double> _calculateBalances(BuildContext context) {
    // Logika Simulasi: 
    double totalIn = _allTransactions.where((t) => t.type.contains('IN') || t.type == 'TOPUP').fold(0.0, (sum, t) => sum + t.amount);
    double totalOut = _allTransactions.where((t) => t.type.contains('OUT') || t.type == 'PAYMENT_PPOB' || t.type == 'PAYMENT_IURAN').fold(0.0, (sum, t) => sum + t.amount);
    
    // Mengambil saldo saat ini dari AuthProvider
    double currentBalance = context.read<AuthProvider>().user?.warga?.wallet?.balance ?? 0.0;
    
    // Mengembalikan data mentah untuk digunakan di _buildBalanceView
    return {
      'currentBalance': currentBalance,
      'totalIn': totalIn,
      'totalOut': totalOut,
    };
  }
  // -----------------------------------------------------------------------------
  
  // Widget untuk menampilkan 1 baris riwayat transaksi
  Widget _buildTransactionTile(Transaction t) {
    final bool isDebit =
        t.type.contains('OUT') || t.type == 'PAYMENT_IURAN' || t.type == 'PAYMENT_PPOB';
    final Color amountColor = isDebit ? _dangerColor : _successColor;
    final String sign = isDebit ? '-' : '+';
    
    String title = t.description ?? t.type;
    
    if (t.type == 'TRANSFER_OUT') title = "Transfer Keluar";
    if (t.type == 'TRANSFER_IN') title = "Transfer Masuk";
    if (t.type == 'TOPUP') title = "Isi Saldo";


    final String targetInfo = (t.receiver?.namaLengkap ?? t.sender?.namaLengkap ?? 'Akun Lain'); 


    final String formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(t.createdAt.toLocal());

    return _buildCardWrapper( 
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), 
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon Debit/Kredit
          CircleAvatar(
            radius: 20, 
            backgroundColor: amountColor.withOpacity(0.1),
            child: Icon(
              isDebit ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              color: amountColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 15),
          
          // Detail Transaksi
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Judul
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _accentColor)), 
                
                // Info Tambahan (Target/Keterangan)
                Text(targetInfo, style: TextStyle(color: Colors.grey[700], fontSize: 13)),

                // Waktu
                Text(formattedDate, style: TextStyle(color: Colors.grey[500], fontSize: 11)), 
              ],
            ),
          ),
          
          // Jumlah dan Biaya
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "$sign ${_rupiahFormatter.format(t.amount)}",
                style: TextStyle(color: amountColor, fontWeight: FontWeight.bold, fontSize: 15),
              ),
              if (t.fee > 0)
                Text(
                  "Biaya: ${_rupiahFormatter.format(t.fee)}",
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                ),
            ],
          ),
        ],
      ),
    );
  }
  
  // Widget Tab Item (untuk filter)
  Widget _buildTabItem(String filterType, String label) {
    final bool isSelected = _currentFilter == filterType;
    
    return InkWell(
      onTap: () {
        if (!isSelected && !_isLoading) {
          setState(() {
            _currentFilter = filterType;
          });
        }
      },
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : _tabIndicatorColor,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 3,
            width: 80, // Lebar fixed untuk indikator
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET: CUSTOM HEADER PROSCAN DENGAN TAB FILTER ---
  Widget _buildCustomHeader(BuildContext context) {
    return Container(
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
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Row Judul dan Back Button
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white), 
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Riwayat Transaksi",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            // Tab Filter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTabItem('ALL', 'Semua'),
                  _buildTabItem('INCOMING', 'Pemasukan'),
                  _buildTabItem('OUTBOUND', 'Pengeluaran'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET: Tampilan Saldo Ringkasan ---
  Widget _buildBalanceView(Map<String, double> balances) {
    final dataView = [
      // Menampilkan Total Saldo Desapay user saat ini
      {'label': 'Saldo Desapay Anda', 'amount': balances['currentBalance']!, 'isTotal': true, 'color': _primaryColor},
      // Menampilkan total Pemasukan 
      {'label': 'Total Pemasukan (Riwayat)', 'amount': balances['totalIn']!, 'isTotal': false, 'color': _successColor},
      // Menampilkan total Pengeluaran
      {'label': 'Total Pengeluaran (Riwayat)', 'amount': balances['totalOut']!, 'isTotal': false, 'color': _dangerColor},
    ];

    return _buildCardWrapper(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "RINGKASAN DOMPET",
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: _accentColor),
          ),
          const Divider(height: 20, thickness: 1, color: Colors.grey),
          
          ...dataView.map((item) {
            final double amount = item['amount'] as double;
            final bool isTotal = item['isTotal'] as bool;
            Color color = item['color'] as Color;
            
            // Khusus Pengeluaran, warnanya _dangerColor
            if (item['label'] == 'Total Pengeluaran (Riwayat)') {
               color = _dangerColor;
            }

            return Padding(
              padding: EdgeInsets.symmetric(vertical: isTotal ? 6.0 : 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item['label'] as String,
                    style: TextStyle(
                      fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                      fontSize: isTotal ? 16 : 14,
                      color: isTotal ? _primaryColor : Colors.black87,
                    ),
                  ),
                  Text(
                    _rupiahFormatter.format(amount),
                    style: TextStyle(
                      color: color,
                      fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
                      fontSize: isTotal ? 16 : 14,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- Logika Filtering berdasarkan Tab ---
    final List<Transaction> filteredTransactions = _allTransactions.where((t) {
      if (_currentFilter == 'ALL') return true;
      
      // Debit (OUT, PPOB, IURAN) adalah Outbound, lainnya (IN, TOPUP) adalah Incoming
      final isDebit = t.type.contains('OUT') || t.type == 'PAYMENT_PPOB' || t.type == 'PAYMENT_IURAN';
      
      if (_currentFilter == 'INCOMING') {
        return !isDebit; 
      }
      
      if (_currentFilter == 'OUTBOUND') {
        return isDebit;
      }
      return false;
    }).toList();
    // ------------------------------------------

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Column(
        children: [
          // 1. HEADER (Custom Header + Tab Filter)
          _buildCustomHeader(context),
          
          // 2. BODY LIST
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchFullHistory,
              color: _primaryColor,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: _primaryColor))
                  : _errorMessage.isNotEmpty
                      ? Center(child: Text("Error: $_errorMessage"))
                      : ListView( 
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                          children: [
                            // 🗹 Kartu Ringkasan Saldo (Baru Ditambahkan)
                            _buildBalanceView(_calculateBalances(context)), 
                            
                            const SizedBox(height: 12),
                            
                            // Subtitle Daftar Transaksi
                            Text(
                              "Daftar Transaksi ${_currentFilter != 'ALL' ? _currentFilter : 'Semua'} (${filteredTransactions.length})",
                              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                                fontWeight: FontWeight.w700,
                                color: _primaryColor,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Daftar Transaksi Terfilter
                            if (filteredTransactions.isEmpty)
                              const Center(child: Padding(
                                padding: EdgeInsets.all(24.0),
                                child: Text("Tidak ada transaksi tercatat untuk filter ini."),
                              ))
                            else
                              ...filteredTransactions.map((t) => _buildTransactionTile(t)).toList(),
                          ],
                        ),
            ),
          ),
        ],
      ),
    );
  }
}