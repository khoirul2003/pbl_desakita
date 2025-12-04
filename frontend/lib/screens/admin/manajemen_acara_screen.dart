import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/models/acara_model.dart'; 
import 'package:frontend/screens/placeholder_screen.dart';
import 'package:frontend/screens/admin/tambah_acara_screen.dart'; 
import 'package:frontend/screens/admin/edit_acara_screen.dart'; 

class ManajemenAcaraScreen extends StatefulWidget {
  const ManajemenAcaraScreen({super.key});

  @override
  State<ManajemenAcaraScreen> createState() =>
      _ManajemenAcaraScreenState();
}

class _ManajemenAcaraScreenState extends State<ManajemenAcaraScreen> {
  List<Acara> _acaraList = [];
  bool _isLoading = true;
  String _errorMessage = "";
  final TextEditingController _searchController = TextEditingController();

  final DateFormat _dateFormat = DateFormat('dd MMM yyyy, HH:mm');
  final NumberFormat _rupiahFormatter = NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _fetchAcara();
  }

  Future<void> _fetchAcara({String? search}) async {
    // Cek mounted sebelum setState
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    final apiService = context.read<ApiService>();

    try {
      final acara = await apiService.getManajemenAcara(search: search);
      
      if (!mounted) return;
      setState(() {
        _acaraList = acara;
        _isLoading = false;
      });

    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = "Gagal memuat data acara: $e";
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal memuat data acara: $e")),
        );
      }
    }
  }

  void _tambahAcara() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const TambahAcaraScreen(),
        fullscreenDialog: true,
      ),
    );
    if (result == true) {
      _fetchAcara(search: _searchController.text);
    }
  }

  void _editAcara(Acara acara) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditAcaraScreen(acara: acara),
        fullscreenDialog: true,
      ),
    );
    if (result == true) {
      _fetchAcara(search: _searchController.text);
    }
  }

  Future<void> _deleteAcara(Acara acara) async {
    final bool? confirmed = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Hapus Acara"),
          content: Text(
            "Apakah Anda yakin ingin menghapus acara '${acara.namaAcara}'?",
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
        final success = await apiService.deleteAcara(acara.id);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Acara '${acara.namaAcara}' berhasil dihapus.",
              ),
              backgroundColor: Colors.green,
            ),
          );
          _fetchAcara(search: _searchController.text);
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

  // Widget untuk Card Acara
  Widget _buildAcaraCard(Acara acara) {
    String scope = 'Desa';
    if (acara.rt != null) {
      scope = "RT ${acara.rt} / RW ${acara.rw}";
    } else if (acara.rw != null) {
      scope = "RW ${acara.rw}";
    }

    final bool isFinished = acara.tanggalSelesai.isBefore(DateTime.now());
    final Color iconColor = isFinished ? Colors.grey : Colors.redAccent; 

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.1),
          child: Icon(Icons.celebration, color: iconColor),
        ),
        title: Text(
          acara.namaAcara,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Tanggal: ${_dateFormat.format(acara.tanggalMulai)}"),
            Text("Lokasi: ${acara.lokasi} ($scope)"),
            // Tampilkan Biaya
            Text(
              "Biaya: ${_rupiahFormatter.format(acara.totalBiaya)}",
              style: const TextStyle(fontSize: 14, color: Colors.red),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              _editAcara(acara);
            } else if (value == 'delete') {
              _deleteAcara(acara);
            } else if (value == 'detail') {
              // Navigasi ke detail acara
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PlaceholderScreen(
                    title: "Detail Acara: ${acara.namaAcara}",
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
          // Aksi onTap utama ke detail acara
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PlaceholderScreen(
                title: "Detail Acara: ${acara.namaAcara}",
              ),
            ),
          );
        },
      ),
    );
  }

  // Widget untuk Header Kustom
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Cari Nama Acara",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                fillColor: Colors.white,
                filled: true,
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (query) => _fetchAcara(search: query),
            ),
          ),
          const SizedBox(width: 12),
          // Tombol + Add
          ElevatedButton.icon(
            onPressed: _tambahAcara,
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

  @override
  Widget build(BuildContext context) {
    // Cek apakah layar ini dapat di-pop (ditutup)
    final bool canPop = Navigator.of(context).canPop();
    
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: canPop,
        title: const Text("Manajemen Acara"),
        centerTitle: false,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        
        // Bagian Bawah AppBar untuk menampung Search dan Add
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70.0), 
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
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
                      : _acaraList.isEmpty
                          ? Center(
                              child: Text(
                                _searchController.text.isEmpty
                                    ? "Belum ada acara yang terdaftar."
                                    : "Tidak ditemukan acara.",
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: () => _fetchAcara(),
                              child: ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.only(top: 8, bottom: 16),
                                itemCount: _acaraList.length,
                                itemBuilder: (context, index) {
                                  return _buildAcaraCard(_acaraList[index]);
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