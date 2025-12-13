// screens/warga/kegiatan_warga_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Wajib ada untuk DateFormat
import 'package:frontend/services/api_service.dart';
import 'package:frontend/models/kegiatan_model.dart'; 
// Asumsi import ini sudah ada
import 'package:frontend/screens/warga/Detail_Kegiatan_Screen.dart'; 

const Color _primaryColor = Color(0xFF0E2F60);
const Color _accentColor = Color(0xFF3C486B);

class KegiatanWargaScreen extends StatefulWidget {
  const KegiatanWargaScreen({super.key});

  @override
  State<KegiatanWargaScreen> createState() => _KegiatanWargaScreenState();
}

class _KegiatanWargaScreenState extends State<KegiatanWargaScreen> {
  List<Kegiatan> _kegiatanList = [];
  bool _isLoading = true;
  String _errorMessage = "";
  final TextEditingController _searchController = TextEditingController();

  final DateFormat _dateTimeFormatter = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    _fetchKegiatan();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    }
  }

  void _onSearchChanged(String query) {
    // Tambahkan debounce jika diperlukan, sementara panggil langsung
    _fetchKegiatan(search: query);
  }

  // Header Disederhanakan (Hanya Judul dan Search Bar)
  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 8,
        20,
        16,
      ),
      decoration: const BoxDecoration(
        color: _primaryColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              "Daftar Kegiatan Warga",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Search Bar
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: "Cari nama kegiatan...",
                prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
            ),
          ),
          // TOMBOL TAMBAH DIHILANGKAN
        ],
      ),
    );
  }

  Widget _buildKegiatanCard(Kegiatan kegiatan) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: () {
          // NAVIGASI KE DETAIL KEGIATAN
          // Perbaikan: Mengirimkan objek 'kegiatan' lengkap
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => DetailKegiatanScreen(
                kegiatan: kegiatan, // Mengirimkan objek Kegiatan
              ),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const Icon(Icons.event_note, color: _accentColor, size: 30),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kegiatan.namaKegiatan, 
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Mulai: ${_dateTimeFormatter.format(kegiatan.tanggalMulai)}",
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    Text(
                      "Selesai: ${_dateTimeFormatter.format(kegiatan.tanggalSelesai)}",
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey), 
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading)
      return const Center(child: CircularProgressIndicator(color: _primaryColor));
      
    if (_kegiatanList.isEmpty) {
      return Center(
        child: Text(
          _searchController.text.isEmpty
              ? "Tidak ada kegiatan yang tersedia saat ini."
              : "Tidak ditemukan kegiatan untuk '${_searchController.text}'.",
          style: const TextStyle(color: Colors.black54),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchKegiatan(search: _searchController.text),
      color: _primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 12, bottom: 24),
        itemCount: _kegiatanList.length,
        itemBuilder: (context, index) => _buildKegiatanCard(_kegiatanList[index]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }
}