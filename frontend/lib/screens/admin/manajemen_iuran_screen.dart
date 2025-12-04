import 'package:flutter/material.dart';
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

  // --- LOGIKA PROGRAM (TIDAK BERUBAH) ---
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
  // --- AKHIR LOGIKA PROGRAM ---

  // =========================================================
  // 👇 MODIFIKASI UI/LAYOUT: _buildHeader TANPA JUDUL
  // =========================================================
  Widget _buildHeader() {
    return Container(
      // Padding vertikal dikurangi karena judul dihapus
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: const BoxDecoration(
        color: Color(0xFF0e2f60), // Warna biru tua
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // JUDUL "IURAN" DIHAPUS

          // Search Box
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Cari Jenis Iuran",
                hintStyle: TextStyle(color: Colors.grey[600]),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
              ),
              onChanged: (query) => _fetchIuran(search: query),
            ),
          ),

          const SizedBox(height: 14),

          // Tombol + Add (Full Width)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _tambahIuran,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text("Tambah Jenis Iuran"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.25), // Latar belakang transparan
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

  // =========================================================
  // 👇 MODIFIKASI UI/LAYOUT: _buildIuranCard (Sama seperti modifikasi sebelumnya)
  // =========================================================
  Widget _buildIuranCard(Iuran iuran) {
    String detailScope = '';

    if (iuran.rt != null && iuran.rt != '000') {
      detailScope = "(RT ${iuran.rt} / RW ${iuran.rw})";
    } else if (iuran.rw != null && iuran.rw != '000') {
      detailScope = "(RW ${iuran.rw})";
    } else {
      detailScope = "(DESA)";
    }

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PlaceholderScreen(
              title: "Kelola Tagihan: ${iuran.namaIuran}",
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Row(
          children: [
            // Avatar/Icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF7FA), 
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Icon(
                  iuran.tipe == 'PER_KELUARGA' ? Icons.house : Icons.person,
                  color: Theme.of(context).colorScheme.primary, 
                  size: 24,
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Info Iuran
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    iuran.namaIuran,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Jumlah: ${_rupiahFormatter.format(iuran.jumlah)}",
                    style: const TextStyle(color: Colors.black54)),
                  Text(
                    "Tipe: ${iuran.tipe.replaceAll('_', ' ')} ${detailScope}",
                    style: const TextStyle(color: Colors.black54)),
                ],
              ),
            ),

            // Menu Popup (LOGIKA TIDAK BERUBAH)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _editIuran(iuran);
                } else if (value == 'delete') {
                  _deleteIuran(iuran);
                } else if (value == 'tagihan') {
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
          ],
        ),
      ),
    );
  }

  // =========================================================
  // 👇 BARU: Widget _buildBody (Listview/Loading/Error)
  // =========================================================
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(child: Text("Error: $_errorMessage"));
    }

    if (_iuranList.isEmpty) {
      return Center(
        child: Text(
          _searchController.text.isEmpty
              ? "Belum ada jenis iuran yang terdaftar."
              : "Tidak ditemukan jenis iuran.",
          style: const TextStyle(color: Colors.black54),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchIuran,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _iuranList.length,
        itemBuilder: (context, index) {
          return _buildIuranCard(_iuranList[index]);
        },
      ),
    );
  }

  // =========================================================
  // 👇 MODIFIKASI: Mengganti struktur Scaffold/AppBar
  // =========================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.grey[200], // Background body
        child: Column(
          children: [
            // Header kustom (Search + Tombol Add TANPA JUDUL)
            _buildHeader(), 

            // Body (List Iuran)
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }
}