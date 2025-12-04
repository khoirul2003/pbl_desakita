import 'package:flutter/material.dart';
import 'package:frontend/screens/admin/detail_iuran_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _fetchIuran();
  }

  Future<void> _fetchIuran({String? search}) async {
    // Cek mounted sebelum setState
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
        _errorMessage = "Gagal memuat data iuran: $e";
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Gagal memuat data iuran: $e")));
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
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Hapus Iuran"),
          content: Text(
            "Apakah Anda yakin ingin menghapus jenis iuran '${iuran.namaIuran}'?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Batal"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Hapus", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
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

  // --- HEADER BARU ---
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
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
          // Judul halaman
          const Text(
            "Halaman Iuran",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
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

  // Widget untuk Card Iuran
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
        // 2. MODIFIKASI ONTAP UNTUK NAVIGASI KE DETAIL
        onTap: () {
          _goToDetailIuran(iuran); // <--- Memanggil fungsi navigasi baru
        },
        child: Stack(
          children: [
            Text("Jumlah: ${_rupiahFormatter.format(iuran.jumlah)}"),
            Text("Tipe: ${iuran.tipe.replaceAll('_', ' ')} (${scope})"),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              _editIuran(iuran);
            } else if (value == 'delete') {
              _deleteIuran(iuran);
            } else if (value == 'tagihan') {
              // Navigasi ke layar manajemen tagihan iuran
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PlaceholderScreen(
                    title: "Kelola Tagihan: ${iuran.namaIuran}",
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
              const PopupMenuItem<String>(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 8),
                    Text("Edit Jenis"),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text("Hapus Jenis", style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ];
          },
        ),
        onTap: () {
          // Aksi onTap utama ke Detail Iuran
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => DetailIuranScreen(iuran: iuran)),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Cek apakah layar ini dapat di-pop (ditutup)
    final bool canPop = Navigator.of(context).canPop();

    return Scaffold(
      // --- PERBAIKAN: Gunakan AppBar standar untuk judul Desakita ---
      appBar: AppBar(
        // Tombol back standar (otomatis muncul jika canPop)
        automaticallyImplyLeading: canPop,
        title: const Text("Manajemen Iuran"), // Judul spesifik layar
        centerTitle: false,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 2,

        // Ganti leading jika berada di BottomBar (untuk tombol menu)
        leading: canPop
            ? null // Biarkan otomatis (back)
            : IconButton(
                // Tombol menu/judul kustom jika di BottomBar
                icon: const Icon(Icons.menu), // Placeholder menu
                onPressed: () {
                  // Aksi untuk membuka drawer atau sejenisnya
                },
              ),

        // Bagian Bawah AppBar untuk menampung Search dan Add
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70.0), // Cukup untuk header
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: _buildHeader(), // Panggil Header (hanya Search/Add)
          ),
        ),
      ),

      // --- AKHIR PERBAIKAN: Gunakan AppBar standar ---
      body: Container(
        color: Colors.grey[200],
        child: Column(
          children: [
            // Konten utama list iuran
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage.isNotEmpty
                  ? Center(child: Text("Error: $_errorMessage"))
                  : _iuranList.isEmpty
                  ? Center(
                      child: Text(
                        _searchController.text.isEmpty
                            ? "Belum ada jenis iuran yang terdaftar."
                            : "Tidak ditemukan jenis iuran.",
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchIuran,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: _iuranList.length,
                        itemBuilder: (context, index) {
                          return _buildIuranCard(_iuranList[index]);
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