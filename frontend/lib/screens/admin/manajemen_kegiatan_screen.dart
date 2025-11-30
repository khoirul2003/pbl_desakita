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

  // Widget untuk Card Kegiatan
  Widget _buildKegiatanCard(Kegiatan kegiatan) {
    String scope = 'Desa';
    if (kegiatan.rt != null) {
      scope = "RT ${kegiatan.rt} / RW ${kegiatan.rw}";
    } else if (kegiatan.rw != null) {
      scope = "RW ${kegiatan.rw}";
    }

    // Tentukan warna berdasarkan waktu
    final bool isFinished = kegiatan.tanggalSelesai.isBefore(DateTime.now());
    final Color iconColor = isFinished ? Colors.grey : Colors.green;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.1),
          child: Icon(Icons.event_note, color: iconColor),
        ),
        title: Text(
          kegiatan.namaKegiatan,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Tanggal: ${_dateFormat.format(kegiatan.tanggalMulai)}"),
            Text("Lokasi: ${kegiatan.lokasi}"),
            Text(
              "Lingkup: $scope",
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              _editKegiatan(kegiatan);
            } else if (value == 'delete') {
              _deleteKegiatan(kegiatan);
            } else if (value == 'detail') {
              // Navigasi ke detail kegiatan
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
        onTap: () {
          // Aksi onTap utama ke detail kegiatan
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PlaceholderScreen(
                title: "Detail Kegiatan: ${kegiatan.namaKegiatan}",
              ),
            ),
          );
        },
      ),
    );
  }

  // Widget untuk Header Kustom
  Widget _buildHeader() {
    // Tombol search dan add yang dipindahkan ke body
    return Container(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
      color: Theme.of(context).colorScheme.primary,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Cari Nama Kegiatan",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                fillColor: Colors.white,
                filled: true,
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (query) => _fetchKegiatan(search: query),
            ),
          ),
          const SizedBox(width: 12),
          // Tombol + Add
          ElevatedButton.icon(
            onPressed: _tambahKegiatan,
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

  @override
  Widget build(BuildContext context) {
    // Cek apakah layar ini dapat di-pop (ditutup)
    final bool canPop = Navigator.of(context).canPop();

    return Scaffold(
      // --- PERBAIKAN: Gunakan AppBar standar untuk judul & back button ---
      appBar: AppBar(
        // Tombol back otomatis muncul jika canPop = true
        // Jika canPop = false (berada di BottomBar), tombol back tidak muncul
        leading: canPop
            ? null
            : const SizedBox(), // Tampilkan tombol back standar, atau SizedBox jika di BottomBar
        automaticallyImplyLeading:
            canPop, // Biarkan sistem memutuskan tombol back
        title: const Text("DesaKita - Manajemen Kegiatan"),
        centerTitle: false,
        // Tambahkan Judul "Desakita" di atas? Judul Desakita ada di HomeScreen.
        // Jika Anda ingin judul yang konsisten dengan "Profil & Pengaturan", biarkan seperti ini.
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0), // Tinggi untuk Search bar
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: _buildHeader(), // Panggil Header di sini
          ),
        ),
      ),

      // --- AKHIR PERBAIKAN: Gunakan AppBar standar ---
      body: Container(
        color: Colors.grey[200],
        child: Column(
          children: [
            // Header Search/Add sudah dipindah ke AppBar.bottom
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
                        padding: const EdgeInsets.all(8.0),
                        itemCount: _kegiatanList.length,
                        itemBuilder: (context, index) {
                          return _buildKegiatanCard(_kegiatanList[index]);
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
