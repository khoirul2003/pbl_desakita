import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/models/keuangan_model.dart'; // Import Model Keuangan
import 'package:frontend/screens/admin/detail_keuangan_screen.dart'; // Import Detail

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

  // Widget untuk Card Keuangan
  Widget _buildKeuanganCard(Keuangan k) {
    final bool isPemasukan = k.tipe == 'PEMASUKAN';
    final Color amountColor = isPemasukan ? Colors.green : Colors.red;
    final String scope = k.rt != null
        ? "RT ${k.rt}/${k.rw}"
        : (k.rw != null ? "RW ${k.rw}" : "Desa");

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: amountColor.withOpacity(0.1),
          child: Icon(
            isPemasukan ? Icons.add : Icons.remove,
            color: amountColor,
          ),
        ),
        title: Text(
          k.keterangan,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Tanggal: ${DateFormat('dd MMM yyyy').format(k.tanggal)} (Kas: $scope)",
            ),
            Text(
              isPemasukan ? "PEMASUKAN" : "PENGELUARAN",
              style: TextStyle(
                color: amountColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: Text(
          _rupiahFormatter.format(
            k.jumlah.abs(),
          ), // Gunakan abs() untuk tampilan
          style: TextStyle(
            color: amountColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        onTap: () {
          // Navigasi ke Detail Keuangan
          // Anda mungkin ingin menambahkan DetailKeuanganScreen di sini
        },
      ),
    );
  }

  // Widget untuk Header Kustom (Hanya Filter)
  Widget _buildHeader() {
    return Container(
      color: Theme.of(context).colorScheme.primary,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Filter Transaksi:",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          DropdownButton<String>(
            value: _filterTipe,
            dropdownColor: Colors.white,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
            items: const [
              DropdownMenuItem(value: 'SEMUA', child: Text('Semua Transaksi')),
              DropdownMenuItem(value: 'PEMASUKAN', child: Text('Pemasukan')),
              DropdownMenuItem(
                value: 'PENGELUARAN',
                child: Text('Pengeluaran'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _filterTipe = value;
                });
              }
            },
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

    return Column(
      children: sortedKeys.map((key) {
        final double balance = balances[key]!;
        final Color color = balance >= 0 ? Colors.green.shade700 : Colors.red;
        final bool isTotal = key.startsWith('TOTAL');

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: isTotal ? 10.0 : 4.0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                key,
                style: TextStyle(
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                  fontSize: isTotal ? 18 : 14,
                ),
              ),
              Text(
                _rupiahFormatter.format(balance.abs()),
                style: TextStyle(
                  color: color,
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
                  fontSize: isTotal ? 18 : 14,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool canPop = Navigator.of(context).canPop();

    // Filter list berdasarkan state _filterTipe
    final List<Keuangan> filteredList = _keuanganList.where((k) {
      if (_filterTipe == 'SEMUA') return true;
      return k.tipe == _filterTipe;
    }).toList();

    final Map<String, double> balances = _calculateBalances();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: canPop,
        title: const Text("Laporan Keuangan Desa"),
        centerTitle: false,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,

        // Bagian Bawah AppBar untuk menampung Header Aksi (Filter)
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0), // Cukup untuk filter
          child: _buildHeader(),
        ),
      ),

      body: Container(
        color: Colors.grey[200],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Saldo Multi-Level Card
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "RINGKASAN SALDO KAS",
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Divider(height: 20, thickness: 1),
                      _buildBalanceView(balances),
                    ],
                  ),
                ),
              ),
            ),

            // Label Daftar Transaksi
            Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                bottom: 8.0,
              ),
              child: Text(
                "DAFTAR TRANSAKSI",
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),

            // Konten utama list Keuangan
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage.isNotEmpty
                  ? Center(child: Text("Error: $_errorMessage"))
                  : filteredList.isEmpty
                  ? const Center(
                      child: Text("Tidak ada data keuangan untuk filter ini."),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchKeuangan,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          return _buildKeuanganCard(filteredList[index]);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
