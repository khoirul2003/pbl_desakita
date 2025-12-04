import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/models/kegiatan_model.dart';
import 'package:frontend/screens/placeholder_screen.dart';
import 'package:frontend/screens/admin/tambah_kegiatan_screen.dart';
import 'package:frontend/screens/admin/edit_kegiatan_screen.dart';

class ManajemenKegiatanScreen extends StatefulWidget {
  const ManajemenKegiatanScreen({super.key});

  @override
  State<ManajemenKegiatanScreen> createState() =>
      _ManajemenKegiatanScreenState();
}

class _ManajemenKegiatanScreenState extends State<ManajemenKegiatanScreen> {
  List<Kegiatan> _kegiatanList = [];
  bool _isLoading = true;
  String _errorMessage = "";
  final TextEditingController _searchController = TextEditingController();

  final DateFormat _dateFormat = DateFormat('dd MMM yyyy, HH:mm');
  final NumberFormat _rupiahFormatter = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _fetchKegiatan();
  }

  Future<void> _fetchKegiatan({String? search}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    final apiService = context.read<ApiService>();

    try {
      final kegiatan = await apiService.getManajemenKegiatan(search: search);

      if (!mounted) return;
      setState(() {
        _kegiatanList = kegiatan;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = "Gagal memuat data kegiatan: $e";
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal memuat data kegiatan: $e")),
        );
      }
    }
  }

  void _tambahKegiatan() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const TambahKegiatanScreen(),
        fullscreenDialog: true,
      ),
    );
    if (result == true) {
      _fetchKegiatan(search: _searchController.text);
    }
  }

  void _editKegiatan(Kegiatan kegiatan) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditKegiatanScreen(kegiatan: kegiatan),
        fullscreenDialog: true,
      ),
    );
    if (result == true) {
      _fetchKegiatan(search: _searchController.text);
    }
  }

  Future<void> _deleteKegiatan(Kegiatan kegiatan) async {
    final bool? confirmed = await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Hapus Kegiatan"),
          content: Text(
            "Apakah Anda yakin ingin menghapus '${kegiatan.namaKegiatan}'?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Batal"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Hapus", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        final apiService = context.read<ApiService>();
        final success = await apiService.deleteKegiatan(kegiatan.id);

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Kegiatan '${kegiatan.namaKegiatan}' berhasil dihapus.",
              ),
              backgroundColor: Colors.green,
            ),
          );
          _fetchKegiatan(search: _searchController.text);
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

  // CARD KEGIATAN
  Widget _buildKegiatanCard(Kegiatan kegiatan) {
    String scope = 'Desa';
    if (kegiatan.rt != null) {
      scope = "RT ${kegiatan.rt} / RW ${kegiatan.rw}";
    } else if (kegiatan.rw != null) {
      scope = "RW ${kegiatan.rw}";
    }

    final bool isFinished = kegiatan.tanggalSelesai.isBefore(DateTime.now());
    final Color iconColor = isFinished ? Colors.grey : Colors.green;

    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: iconColor.withOpacity(0.15),
              child: Icon(Icons.event_note, color: iconColor, size: 28),
            ),
            const SizedBox(width: 14),

            // --- Text Section ---
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kegiatan.namaKegiatan,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text("Tanggal: ${_dateFormat.format(kegiatan.tanggalMulai)}"),
                  Text("Lokasi: ${kegiatan.lokasi} ($scope)"),
                  // Tampilkan Biaya
                  Text(
                    "Biaya: ${_rupiahFormatter.format(kegiatan.totalBiaya)}",
                    style: const TextStyle(fontSize: 14, color: Colors.red),
                  ),
                ],
              ),
            ),

            // Menu
            PopupMenuButton(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == "detail") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PlaceholderScreen(
                        title: "Detail Kegiatan: ${kegiatan.namaKegiatan}",
                      ),
                    ),
                  );
                } else if (value == "edit") {
                  _editKegiatan(kegiatan);
                } else if (value == "delete") {
                  _deleteKegiatan(kegiatan);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: "detail",
                  child: Row(
                    children: [
                      Icon(Icons.visibility, size: 20),
                      SizedBox(width: 8),
                      Text("Lihat Detail"),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: "edit",
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text("Edit"),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: "delete",
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text("Hapus", style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // SEARCH BAR + ADD BUTTON — AppBar bottom
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) => _fetchKegiatan(search: value),
              decoration: InputDecoration(
                hintText: "Cari Nama Kegiatan...",
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Tombol Add
          ElevatedButton.icon(
            onPressed: _tambahKegiatan,
            icon: const Icon(Icons.add, color: Colors.black),
            label: const Text("Add", style: TextStyle(color: Colors.black)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.yellow,
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

  // BUILD UTAMA
  @override
  Widget build(BuildContext context) {
    final bool canPop = Navigator.of(context).canPop();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: canPop,
        leading: canPop ? null : const SizedBox(),
        title: const Text("Manajemen Kegiatan"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 4.0,
            ),
            child: _buildHeader(),
          ),
        ),
      ),

      body: Container(
        color: Colors.grey[100],
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage.isNotEmpty
                  ? Center(child: Text("Error: $_errorMessage"))
                  : _kegiatanList.isEmpty
                  ? Center(
                      child: Text(
                        _searchController.text.isEmpty
                            ? "Belum ada kegiatan yang terdaftar."
                            : "Tidak ditemukan kegiatan.",
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => _fetchKegiatan(),
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(top: 8, bottom: 16),
                        itemCount: _kegiatanList.length,
                        itemBuilder: (_, i) {
                          return _buildKegiatanCard(_kegiatanList[i]);
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
