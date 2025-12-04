import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/models/keuangan_model.dart'; // Import Model Keuangan
import 'package:frontend/screens/admin/detail_keuangan_screen.dart'; // Import Detail

// --- DEFINISI WARNA PROSCAN ---
const Color _primaryColor = Color(0xFF0E2F60); // Biru Tua
const Color _accentColor = Color(0xFF3C486B); // Aksen Biru/Abu
const Color _backgroundColor = Color(0xFFF5F5F5); // Abu-abu muda untuk Scaffold
const Color _successColor = Color(0xFF28A745); // Hijau untuk Pemasukan
const Color _expenseColor = Colors.red; // Merah untuk Pengeluaran

class ManajemenKeuanganScreen extends StatefulWidget {
  const ManajemenKeuanganScreen({super.key});

  @override
  State<ManajemenKeuanganScreen> createState() =>
      _ManajemenKeuanganScreenState();
}

class _ManajemenKeuanganScreenState extends State<ManajemenKeuanganScreen> {
  List<Keuangan> _keuanganList = [];
  bool _isLoading = true;
  String _errorMessage = "";
  String _filterTipe = 'SEMUA'; // Filter: 'SEMUA', 'PEMASUKAN', 'PENGELUARAN'

  final NumberFormat _rupiahFormatter = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _fetchKeuangan();
  }

  Future<void> _fetchKeuangan() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    final apiService = context.read<ApiService>();

    try {
      // Panggil API untuk mendapatkan semua data keuangan (Admin/RT/RW)
      final keuangan = await apiService.getManajemenKeuangan();

      if (!mounted) return;
      setState(() {
        _keuanganList = keuangan;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = "Gagal memuat data keuangan: $e";
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal memuat data keuangan: $e")),
        );
      }
    }
  }

  // --- LOGIKA PERHITUNGAN SALDO MULTI-LEVEL ---
  Map<String, double> _calculateBalances() {
    Map<String, double> balances = {};

    for (var k in _keuanganList) {
      double amount = k.tipe == 'PEMASUKAN' ? k.jumlah : -k.jumlah;
      String key;

      // Tentukan key berdasarkan level (RT/RW/Desa)
      if (k.rt != null && k.rw != null) {
        // Kas RT Tertentu
        key = "RT ${k.rt}/${k.rw}";
      } else if (k.rw != null && k.rt == null) {
        // Kas RW Umum
        key = "RW ${k.rw} (Umum)";
      } else {
        // Kas Desa/Admin
        key = "Desa (Umum)";
      }

      balances[key] = (balances[key] ?? 0.0) + amount;
    }

    // Tambahkan Total Saldo Keseluruhan
    double totalAll = balances.values.fold(
      0.0,
      (sum, balance) => sum + balance,
    );
    balances['TOTAL KAS DESA'] = totalAll;

    return balances;
  }
  
  // --- WIDGET BANTUAN: CARD WRAPPER DENGAN SHADOW PROSCAN ---
  Widget _buildCardWrapper({required Widget child, EdgeInsets padding = const EdgeInsets.all(16)}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16, // Shadow menonjol dan lembut
            offset: const Offset(0, 6),
          )
        ],
      ),
      padding: padding,
      child: child,
    );
  }

  // Widget untuk Card Transaksi (mengganti _buildKeuanganCard)
  Widget _buildTransactionCard(Keuangan k) {
    final bool isPemasukan = k.tipe == 'PEMASUKAN';
    final Color amountColor = isPemasukan ? _successColor : _expenseColor;
    final String scope = k.rt != null
        ? "RT ${k.rt}/${k.rw}"
        : (k.rw != null ? "RW ${k.rw}" : "Desa");

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 6.0),
      child: _buildCardWrapper(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: InkWell( // Menggunakan InkWell untuk efek tap pada keseluruhan card wrapper
          onTap: () {
            // Navigasi ke Detail Keuangan
            // Anda mungkin ingin menambahkan DetailKeuanganScreen di sini
            Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => DetailKeuanganScreen(keuangan: k))
            );
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: amountColor.withOpacity(0.1),
                child: Icon(
                  isPemasukan ? Icons.add_circle_outline : Icons.remove_circle_outline,
                  color: amountColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      k.keterangan,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.black87),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Tanggal: ${DateFormat('dd MMM yyyy').format(k.tanggal)}",
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Kas: $scope",
                      style: TextStyle(
                        color: _accentColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _rupiahFormatter.format(k.jumlah.abs()),
                    style: TextStyle(
                      color: amountColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    isPemasukan ? "PEMASUKAN" : "PENGELUARAN",
                    style: TextStyle(
                      color: amountColor.withOpacity(0.8),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget untuk Header Kustom (Ikon tambah dihapus)
  Widget _buildCustomHeader(BuildContext context) {
    final bool canPop = Navigator.of(context).canPop();

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              canPop
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    )
                  : const SizedBox(width: 48), // Spacer jika tidak ada back button
              const Text(
                "Laporan Keuangan Desa",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // IKON TAMBAH TRANSAKSI DIHAPUS, DIGANTI DENGAN SPACER
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 12),
          // Dropdown Filter di dalam Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.5)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _filterTipe,
                isExpanded: true,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                icon: const Icon(Icons.filter_list, color: Colors.white),
                dropdownColor: _primaryColor,
                items: const [
                  DropdownMenuItem(value: 'SEMUA', child: Text('Semua Transaksi', style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(value: 'PEMASUKAN', child: Text('Pemasukan', style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(value: 'PENGELUARAN', child: Text('Pengeluaran', style: TextStyle(color: Colors.white))),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _filterTipe = value;
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }


  // Widget untuk Tampilan Saldo Multi-Level
  Widget _buildBalanceView(Map<String, double> balances) {
    final sortedKeys = balances.keys.toList()
      ..sort((a, b) {
        if (a.startsWith('TOTAL')) return -1;
        if (b.startsWith('TOTAL')) return 1;
        if (a.startsWith('Desa')) return -1;
        if (b.startsWith('Desa')) return 1;
        return a.compareTo(b);
      });

    return _buildCardWrapper(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "RINGKASAN SALDO KAS",
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: _accentColor),
          ),
          const Divider(height: 20, thickness: 1, color: Colors.grey),
          
          ...sortedKeys.map((key) {
            final double balance = balances[key]!;
            final Color color = balance >= 0 ? _successColor : _expenseColor;
            final bool isTotal = key.startsWith('TOTAL');

            return Padding(
              padding: EdgeInsets.symmetric(
                vertical: isTotal ? 10.0 : 4.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    key,
                    style: TextStyle(
                      fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                      fontSize: isTotal ? 16 : 14,
                      color: isTotal ? _primaryColor : Colors.black87,
                    ),
                  ),
                  Text(
                    _rupiahFormatter.format(balance.abs()),
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
    // Filter list berdasarkan state _filterTipe
    final List<Keuangan> filteredList = _keuanganList.where((k) {
      if (_filterTipe == 'SEMUA') return true;
      return k.tipe == _filterTipe;
    }).toList();

    final Map<String, double> balances = _calculateBalances();

    return Scaffold(
      backgroundColor: _backgroundColor, // Latar belakang abu-abu muda
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Kustom Biru
          _buildCustomHeader(context),

          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchKeuangan,
              color: _primaryColor,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                children: [
                  // Saldo Multi-Level Card
                  _buildBalanceView(balances),

                  // Label Daftar Transaksi
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 8.0, left: 4),
                    child: Text(
                      "DAFTAR TRANSAKSI",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: _primaryColor,
                      ),
                    ),
                  ),

                  // Konten utama list Keuangan
                  _isLoading
                      ? const Center(child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(color: _primaryColor),
                        ))
                      : _errorMessage.isNotEmpty
                      ? Center(child: Text("Error: $_errorMessage"))
                      : filteredList.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Text("Tidak ada data keuangan untuk filter ini."),
                          )
                        )
                      : Column(
                          children: filteredList.map((k) => _buildTransactionCard(k)).toList(),
                        ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}