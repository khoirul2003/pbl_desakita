import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/models/iuran_model.dart';
import 'package:frontend/screens/placeholder_screen.dart';
import 'package:frontend/screens/admin/tambah_iuran_screen.dart';
import 'package:frontend/screens/admin/edit_iuran_screen.dart';
// 1. IMPOR DETAIL IURAN SCREEN
import 'package:frontend/screens/admin/detail_iuran_screen.dart'; // <--- PASTIKAN PATH INI BENAR

class ManajemenIuranScreen extends StatefulWidget {
  const ManajemenIuranScreen({super.key});

  @override
  State<ManajemenIuranScreen> createState() => _ManajemenIuranScreenState();
}

class _ManajemenIuranScreenState extends State<ManajemenIuranScreen> {
  List<Iuran> _iuranList = [];
  bool _isLoading = true;
  String _errorMessage = "";
  final TextEditingController _searchController = TextEditingController();

  final NumberFormat _rupiahFormatter = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  // --- WARNA TEMA ---
  static const Color _accentColor = Color(0xFF3C486B);
  static const Color _cardIndicator = Color(0xFF6C4BA3);

  @override
  void initState() {
    super.initState();
    _fetchIuran();
  }

  Future<void> _fetchIuran({String? search}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    final apiService = context.read<ApiService>();
    try {
      final iuran = await apiService.getManajemenIuran(search: search);
      if (!mounted) return;
      setState(() {
        _iuranList = iuran;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = "Gagal memuat data iuran";
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal memuat data iuran: $e")),
        );
      }
    }
  }

  void _tambahIuran() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const TambahIuranScreen(),
        fullscreenDialog: true,
      ),
    );
    if (result == true) {
      _fetchIuran(search: _searchController.text);
    }
  }

  void _editIuran(Iuran iuran) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditIuranScreen(iuran: iuran),
        fullscreenDialog: true,
      ),
    );
    if (result == true) {
      _fetchIuran(search: _searchController.text);
    }
  }

  // --- FUNGSI BARU: NAVIGASI KE DETAIL IURAN ---
  void _goToDetailIuran(Iuran iuran) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DetailIuranScreen(iuran: iuran),
      ),
    );
    // Refresh data setelah kembali dari halaman detail (jika ada perubahan)
    _fetchIuran(search: _searchController.text);
  }


  Future<void> _deleteIuran(Iuran iuran) async {
    final bool? confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Iuran"),
        content: Text(
            "Apakah Anda yakin ingin menghapus jenis iuran '${iuran.namaIuran}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Hapus",
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final apiService = context.read<ApiService>();
      try {
        final success = await apiService.deleteIuran(iuran.id);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("${iuran.namaIuran} berhasil dihapus."),
              backgroundColor: Colors.green,
            ),
          );
          _fetchIuran(search: _searchController.text);
        } else if (mounted) {
          throw Exception("Gagal menghapus dari server");
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  // --- HEADER BARU YANG DIMODIFIKASI ---
  Widget _buildHeader() {
    return Container(
      // Padding atas disesuaikan
      padding: EdgeInsets.fromLTRB(
        20, 
        MediaQuery.of(context).padding.top + 8, // Mengambil padding sistem dan menambahkan 8
        20, 
        16
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0E2F60),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Judul halaman: DIBUNGKUS DENGAN CENTER
          Center(
            child: const Text(
              "Halaman Iuran",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20, // Ukuran font disesuaikan
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Search
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (query) => _fetchIuran(search: query),
              decoration: InputDecoration(
                hintText: "Cari jenis iuran...",
                prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _tambahIuran,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text("Tambah Iuran"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.25),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIuranCard(Iuran iuran) {
    String scope = 'Desa';
    if (iuran.rt != null) {
      scope = "RT ${iuran.rt} / RW ${iuran.rw}";
    } else if (iuran.rw != null) {
      scope = "RW ${iuran.rw}";
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        // MODIFIKASI ONTAP UNTUK NAVIGASI KE DETAIL
        onTap: () {
          _goToDetailIuran(iuran); // <--- Memanggil fungsi navigasi baru
        },
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: _accentColor.withOpacity(0.1),
                    child: Icon(
                      iuran.tipe == 'PER_KELUARGA'
                          ? Icons.house
                          : Icons.person,
                      color: _accentColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          iuran.namaIuran,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _rupiahFormatter.format(iuran.jumlah),
                          style: TextStyle(
                              fontWeight: FontWeight.w600, color: _accentColor),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${iuran.tipe.replaceAll('_', ' ')} • $scope',
                          style: TextStyle(
                              color: Colors.grey[600], fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editIuran(iuran);
                      } else if (value == 'delete') {
                        _deleteIuran(iuran);
                      }
                      // Opsi 'tagihan' telah dihapus, sehingga tidak ada lagi else if (value == 'tagihan')
                    },
                    itemBuilder: (context) => [
                      // Opsi 'Kelola Tagihan' telah dihapus dari sini

                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text("Edit Jenis"),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Text("Hapus Jenis",
                                style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
            Positioned(
              left: 0,
              top: 8,
              bottom: 8,
              child: Container(
                width: 6,
                decoration: BoxDecoration(
                  color: _cardIndicator,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                    topRight: Radius.circular(6),
                    bottomRight: Radius.circular(6),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(_errorMessage),
                        ),
                      )
                    : _iuranList.isEmpty
                        ? Center(
                            child: Text(
                              _searchController.text.isEmpty
                                  ? 'Belum ada jenis iuran yang terdaftar.'
                                  : 'Tidak ditemukan jenis iuran.',
                              textAlign: TextAlign.center,
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () =>
                                _fetchIuran(search: _searchController.text),
                            color: _accentColor,
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.only(top: 12, bottom: 24),
                              itemCount: _iuranList.length,
                              itemBuilder: (context, index) =>
                                  _buildIuranCard(_iuranList[index]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}