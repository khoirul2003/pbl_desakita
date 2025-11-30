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
      padding: const EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        bottom: 16.0,
        top: 8.0,
      ),

      color: Theme.of(context).colorScheme.primary,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Cari Warga (Nama atau NIK)",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                fillColor: Colors.white,
                filled: true,
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          const SizedBox(width: 12),

          ElevatedButton.icon(
            onPressed: _tambahWarga,
            icon: const Icon(Icons.add, color: Colors.black),
            label: const Text("Add"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.yellow,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
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
            "Error: $_errorMessage\n\nPastikan server Laravel berjalan.",
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
              : "Tidak ada warga yang cocok dengan pencarian '${_searchController.text}'.",
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchWarga(search: _searchController.text),
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _wargaList.length,
        itemBuilder: (context, index) {
          final warga = _wargaList[index];

          return _buildWargaCard(warga);
        },
      ),
    );
  }

  Widget _buildWargaCard(Warga warga) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.grey[300],
          child: Text(
            warga.namaLengkap.isNotEmpty
                ? warga.namaLengkap[0].toUpperCase()
                : "?",
            style: const TextStyle(color: Colors.black54),
          ),
        ),
        title: Text(
          warga.namaLengkap,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("NIK: ${warga.nik}"),
            Text("RW: ${warga.rw} | RT: ${warga.rt}"),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              // Panggil fungsi Edit yang benar
              _goToEditWarga(warga);
            } else if (value == 'delete') {
              _deleteWarga(warga);
            }
          },
          itemBuilder: (BuildContext context) {
            return [
              const PopupMenuItem<String>(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 8),
                    Text("Edit"),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text("Delete", style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ];
          },
        ),
        onTap: () {
          // Aksi onTap utama adalah ke Detail
          _goToDetail(warga);
        },
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
