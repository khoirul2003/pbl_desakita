import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/models/kegiatan_model.dart'; // Import Model Kegiatan
import 'package:frontend/screens/placeholder_screen.dart'; // Untuk detail
import 'package:frontend/screens/admin/tambah_kegiatan_screen.dart'; // Import Tambah
import 'package:frontend/screens/admin/edit_kegiatan_screen.dart'; // Import Edit

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

  @override
  void initState() {
    super.initState();
    _fetchKegiatan();
  }

  // --- LOGIKA PROGRAM (TIDAK BERUBAH) ---
  Future<void> _fetchKegiatan({String? search}) async {
    // [1] Set loading state di awal
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    final apiService = context.read<ApiService>();

    try {
      final kegiatan = await apiService.getManajemenKegiatan(search: search);

      // [2] Cek mounted sebelum setState di blok try
      if (!mounted) return;
      setState(() {
        _kegiatanList = kegiatan;
        _isLoading = false;
      });
    } catch (e) {
      // [3] Cek mounted sebelum setState di blok catch
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = "Gagal memuat data kegiatan: $e";
      });
      // Tampilkan SnackBar hanya jika masih mounted
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
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Hapus Kegiatan"),
          content: Text(
            "Apakah Anda yakin ingin menghapus kegiatan '${kegiatan.namaKegiatan}'?",
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
        final success = await apiService.deleteKegiatan(kegiatan.id);
        // Cek mounted sebelum setState setelah proses await selesai
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
  // 👇 MODIFIKASI UI/LAYOUT: _buildHeader (Gaya Gambar 2, TANPA JUDUL)
  // =========================================================
  Widget _buildHeader() {
    return Container(
      // Padding vertikal
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
          // JUDUL DIHAPUS

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
                hintText: "Cari Nama Kegiatan",
                hintStyle: TextStyle(color: Colors.grey[600]),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
              ),
              onChanged: (query) => _fetchKegiatan(search: query),
            ),
          ),

          const SizedBox(height: 14),

          // Tombol + Add (Full Width)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _tambahKegiatan,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text("Tambah Kegiatan"),
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
  // 👇 MODIFIKASI UI/LAYOUT: _buildKegiatanCard (Gaya Gambar 2)
  // =========================================================
  Widget _buildKegiatanCard(Kegiatan kegiatan) {
    String scope = 'Desa';
    if (kegiatan.rt != null) {
      scope = "RT ${kegiatan.rt} / RW ${kegiatan.rw}";
    } else if (kegiatan.rw != null) {
      scope = "RW ${kegiatan.rw}";
    }

    final bool isFinished = kegiatan.tanggalSelesai.isBefore(DateTime.now());
    // Warna icon disesuaikan dengan tema biru/putih dan abu-abu jika selesai
    final Color iconColor = isFinished ? Colors.grey : const Color(0xFF0e2f60); 

    return GestureDetector(
      onTap: () {
        // Aksi onTap utama ke detail kegiatan (LOGIKA TIDAK BERUBAH)
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PlaceholderScreen(
              title: "Detail Kegiatan: ${kegiatan.namaKegiatan}",
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
                color: iconColor.withOpacity(0.1), // Background avatar
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Icon(Icons.event_note, color: iconColor, size: 24),
              ),
            ),

            const SizedBox(width: 16),

            // Info Kegiatan
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kegiatan.namaKegiatan,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text("Tanggal: ${_dateFormat.format(kegiatan.tanggalMulai)}",
                      style: const TextStyle(color: Colors.black54)),
                  Text("Lokasi: ${kegiatan.lokasi}",
                      style: const TextStyle(color: Colors.black54)),
                  Text(
                    "Lingkup: $scope",
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ],
              ),
            ),

            // Menu Popup (LOGIKA TIDAK BERUBAH)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _editKegiatan(kegiatan);
                } else if (value == 'delete') {
                  _deleteKegiatan(kegiatan);
                } else if (value == 'detail') {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PlaceholderScreen(
                        title: "Detail Kegiatan: ${kegiatan.namaKegiatan}",
                      ),
                    ),
                  );
                }
              },
              itemBuilder: (BuildContext context) {
                return [
                  const PopupMenuItem<String>(
                    value: 'detail',
                    child: Row(
                      children: [
                        Icon(Icons.visibility, size: 20),
                        SizedBox(width: 8),
                        Text("Lihat Detail"),
                      ],
                    ),
                  ),
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
                        Text("Hapus", style: TextStyle(color: Colors.red)),
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

    if (_kegiatanList.isEmpty) {
      return Center(
        child: Text(
          _searchController.text.isEmpty
              ? "Belum ada kegiatan yang terdaftar."
              : "Tidak ditemukan kegiatan.",
          style: const TextStyle(color: Colors.black54),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchKegiatan(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0), // Padding disesuaikan
        itemCount: _kegiatanList.length,
        itemBuilder: (context, index) {
          return _buildKegiatanCard(_kegiatanList[index]);
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

            // Body (List Kegiatan)
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }
}