import 'package:flutter/material.dart';
import 'package:frontend/screens/admin/detail_iuran_screen.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/models/iuran_model.dart';
import 'package:frontend/screens/placeholder_screen.dart';
import 'package:frontend/screens/admin/tambah_iuran_screen.dart';
import 'package:frontend/screens/admin/edit_iuran_screen.dart';

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

  // Widget untuk Header Kustom (Hanya berisi Search dan Add)
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (query) => _fetchIuran(search: query),
              decoration: InputDecoration(
                hintText: "Cari Jenis Iuran",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                fillColor: Colors.white,
                filled: true,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.0),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Tombol + Add
          ElevatedButton.icon(
            onPressed: _tambahIuran,
            icon: const Icon(Icons.add, color: Colors.black),
            label: const Text("Add", style: TextStyle(color: Colors.black)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.yellow,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(
            context,
          ).colorScheme.secondary.withOpacity(0.1),
          child: Icon(
            iuran.tipe == 'PER_KELUARGA' ? Icons.house : Icons.person,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          iuran.namaIuran,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                ),
              );
            }
          },
          itemBuilder: (BuildContext context) {
            return [
              const PopupMenuItem<String>(
                value: 'tagihan',
                child: Row(
                  children: [
                    Icon(Icons.list_alt, size: 20),
                    SizedBox(width: 8),
                    Text("Kelola Tagihan"),
                  ],
                ),
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
