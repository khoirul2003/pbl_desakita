import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/models/acara_model.dart'; 
import 'package:frontend/screens/placeholder_screen.dart';
import 'package:frontend/screens/admin/tambah_acara_screen.dart'; 
import 'package:frontend/screens/admin/edit_acara_screen.dart'; 
// --- Import Detail Acara Screen ---
import 'package:frontend/screens/admin/detail_acara_screen.dart'; // <--- Import Detail Acara

// --- DEFINISI WARNA PROSCAN ---
const Color _primaryColor = Color(0xFF0E2F60); // Biru Tua
const Color _accentColor = Color(0xFF3C486B); // Aksen Biru/Abu
const Color _backgroundColor = Color(0xFFF5F5F5); // Abu-abu muda untuk Scaffold
const Color _eventColor = Colors.redAccent; // Warna untuk Biaya Acara
const Color _finishedColor = Colors.grey; // Warna untuk Acara Selesai
const Color _upcomingColor = Color(0xFF28A745); // Hijau untuk Status Akan Datang

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

  // --- FUNGSI GO TO DETAIL DIUBAH UNTUK DETAIL_ACARA_SCREEN ---
  void _goToDetailAcara(Acara acara) {
    Navigator.of(context).push(
        MaterialPageRoute(
          // Menggunakan DetailAcaraScreen
          builder: (_) => DetailAcaraScreen(acara: acara), 
        ),
      );
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
  
  // --- WIDGET BANTUAN: CARD WRAPPER DENGAN SHADOW PROSCAN ---
  Widget _buildCardWrapper({required Widget child, EdgeInsets padding = const EdgeInsets.all(16)}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16, // Shadow menonjol dan lembut
            offset: const Offset(0, 6),
          )
        ],
      ),
      padding: padding,
      child: child,
    );
  }

  // Widget untuk Card Acara (Diperbarui dengan gaya ProScan)
  Widget _buildAcaraCard(Acara acara) {
    String scope = 'Desa';
    if (acara.rt != null) {
      scope = "RT ${acara.rt} / RW ${acara.rw}";
    } else if (acara.rw != null) {
      scope = "RW ${acara.rw}";
    }

    final bool isFinished = acara.tanggalSelesai.isBefore(DateTime.now());
    final Color iconColor = isFinished ? _finishedColor : _primaryColor; 
    final String statusText = isFinished ? 'SELESAI' : 'AKAN DATANG';
    final Color statusColor = isFinished ? _finishedColor : _upcomingColor; // Hijau/Success Color

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: () => _goToDetailAcara(acara), // Aksi onTap utama ke Detail Acara
        child: Stack( // Menggunakan Stack untuk indikator sisi kiri (jika diperlukan)
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: iconColor.withOpacity(0.1),
                    child: Icon(Icons.celebration, color: iconColor),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          acara.namaAcara,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: _primaryColor),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Lokasi: ${acara.lokasi}", 
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Tanggal: ${_dateFormat.format(acara.tanggalMulai)}", 
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        // Status dan Biaya di baris terpisah
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 12, 
                                fontWeight: FontWeight.bold, 
                                color: statusColor
                              ),
                            ),
                            Text(
                              _rupiahFormatter.format(acara.totalBiaya),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _eventColor),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // POPUP MENU BUTTON DIMODIFIKASI
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.grey),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editAcara(acara);
                      } else if (value == 'delete') {
                        _deleteAcara(acara);
                      } 
                      // Opsi 'detail' dihapus, karena sudah ditangani oleh onTap utama
                    },
                    itemBuilder: (BuildContext context) {
                      return [
                        // OPSI 'LIHAT DETAIL' DIHAPUS
                        
                        const PopupMenuItem<String>(
                          value: 'edit',
                          child: Row(children: [Icon(Icons.edit, size: 20), SizedBox(width: 8), Text("Edit")]),
                        ),
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 20), SizedBox(width: 8), Text("Hapus", style: TextStyle(color: Colors.red))]),
                        ),
                      ];
                    },
                  ),
                ],
              ),
            ),
            // Indikator status (mirip Manajemen Warga, RT, Iuran)
            Positioned(
              left: 0,
              top: 8,
              bottom: 8,
              child: Container(
                width: 6,
                decoration: BoxDecoration(
                  color: iconColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                    topRight: Radius.circular(6),
                    bottomRight: Radius.circular(6),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget untuk Header Kustom (Gaya Manajemen Warga)
  Widget _buildHeader() {
    final bool canPop = Navigator.of(context).canPop();

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 20,
        right: 20,
        bottom: 16,
      ),
      decoration: const BoxDecoration(
        color: _primaryColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Back Button (jika ada)
              canPop
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    )
                  : const SizedBox(width: 48), // Spacer jika tidak ada back button

              // Judul Halaman di Tengah
              const Text(
                "Manajemen Acara",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              // Spacer PENGGANTI TOMBOL TAMBAH
              const SizedBox(width: 48), 
            ],
          ),
          const SizedBox(height: 12),
          // Search Field
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (query) => _fetchAcara(search: query),
              decoration: InputDecoration(
                hintText: "Cari Nama Acara...",
                prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Tombol Tambah
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _tambahAcara,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text("Tambah Acara"),
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: _primaryColor))
                : _errorMessage.isNotEmpty
                    ? Center(child: Text("Error: $_errorMessage"))
                    : _acaraList.isEmpty
                        ? Center(
                              child: Text(
                                _searchController.text.isEmpty
                                    ? "Belum ada acara yang terdaftar."
                                    : "Tidak ditemukan acara.",
                                textAlign: TextAlign.center,
                              ),
                            )
                        : RefreshIndicator(
                            onRefresh: () => _fetchAcara(search: _searchController.text),
                            color: _primaryColor,
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
    );
  }
}