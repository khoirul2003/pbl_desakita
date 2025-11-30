import 'package:flutter/material.dart';
import 'package:frontend/models/user_model.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/screens/admin/tambah_warga_screen.dart';
import 'package:provider/provider.dart';
import 'package:frontend/screens/admin/detail_warga_screen.dart';
// --- (WAJIB) Import layar edit ---
import 'package:frontend/screens/admin/edit_warga_screen.dart';

class ManajemenWargaScreen extends StatefulWidget {
  const ManajemenWargaScreen({super.key});

  @override
  State<ManajemenWargaScreen> createState() => _ManajemenWargaScreenState();
}

class _ManajemenWargaScreenState extends State<ManajemenWargaScreen> {
  List<Warga> _wargaList = [];
  bool _isLoading = true;
  String _errorMessage = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchWarga();
  }

  Future<void> _fetchWarga({String? search}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    print("Memulai fetch data warga...");
    final apiService = context.read<ApiService>();

    try {
      final warga = await apiService.getManajemenWarga(search: search);
      print("Fetch selesai. Ditemukan ${warga.length} data warga.");

      setState(() {
        _wargaList = warga;
        _isLoading = false;
      });
    } catch (e) {
      print("Error saat fetch warga: $e");
      setState(() {
        _isLoading = false;
        _errorMessage = "Gagal memuat data: $e";
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Gagal memuat data warga: $e")));
      }
    }
  }

  void _onSearchChanged(String query) {
    _fetchWarga(search: query);
  }

  void _tambahWarga() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const TambahWargaScreen(),
        fullscreenDialog: true,
      ),
    );
    if (result == true) {
      _fetchWarga(search: _searchController.text);
    }
  }

  Future<void> _deleteWarga(Warga warga) async {
    final bool? confirmed = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Hapus Warga"),
          content: Text(
            "Apakah Anda yakin ingin menghapus ${warga.namaLengkap}?",
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
        final success = await apiService.deleteWarga(warga.id);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("${warga.namaLengkap} berhasil dihapus."),
              backgroundColor: Colors.green,
            ),
          );

          _fetchWarga(search: _searchController.text);
        } else {
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

  // --- (PERUBAHAN) Fungsi untuk navigasi ke Detail ---
  void _goToDetail(Warga warga) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DetailWargaScreen(wargaAwal: warga)),
    );
  }

  // --- (BARU) Fungsi untuk navigasi ke Edit ---
  Future<void> _goToEditWarga(Warga warga) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditWargaScreen(warga: warga),
        fullscreenDialog: true,
      ),
    );
    // Jika 'true' dikembalikan, refresh list
    if (result == true) {
      _fetchWarga(search: _searchController.text);
    }
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: const BoxDecoration(
        color: Color(0xFF0e2f60),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                hintText: "Cari nama atau NIK...",
                hintStyle: TextStyle(color: Colors.grey[600]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[600]),

                border: InputBorder.none,

                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
              ),
              onChanged: _onSearchChanged,
            ),
          ),

          const SizedBox(height: 14),

          // Tombol Add
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _tambahWarga,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text("Tambah Warga"),
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

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "Error: $_errorMessage",
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_wargaList.isEmpty) {
      return Center(
        child: Text(
          _searchController.text.isEmpty
              ? "Tidak ada data warga."
              : "Tidak ada kecocokan untuk '${_searchController.text}'.",
          style: const TextStyle(color: Colors.black54),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchWarga(search: _searchController.text),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _wargaList.length,
        itemBuilder: (context, index) {
          return _buildWargaCard(_wargaList[index]);
        },
      ),
    );
  }


  Widget _buildWargaCard(Warga warga) {
    return GestureDetector(
      onTap: () => _goToDetail(warga),
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
            // Avatar
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF7FA),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  warga.namaLengkap.isNotEmpty
                      ? warga.namaLengkap[0].toUpperCase()
                      : "?",
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.blueGrey[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    warga.namaLengkap,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text("NIK: ${warga.nik}",
                      style: const TextStyle(color: Colors.black54)),
                  Text("RW: ${warga.rw} | RT: ${warga.rt}",
                      style: const TextStyle(color: Colors.black54)),
                ],
              ),
            ),

            // Menu
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') _goToEditWarga(warga);
                if (value == 'delete') _deleteWarga(warga);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text("Edit"),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text("Delete", style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.grey[200],
        child: Column(
          children: [
            _buildHeader(),

            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }
}
