import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/models/kegiatan_model.dart';
import 'package:frontend/screens/warga/detail_kegiatan_warga_screen.dart'; 

class KegiatanWargaScreen extends StatefulWidget {
  const KegiatanWargaScreen({super.key});

  @override
  State<KegiatanWargaScreen> createState() =>
      _KegiatanWargaScreenState();
}

class _KegiatanWargaScreenState extends State<KegiatanWargaScreen> {
  List<Kegiatan> _kegiatanList = [];
  bool _isLoading = true;
  String _errorMessage = "";
  final TextEditingController _searchController = TextEditingController();

  final DateFormat _dateFormat = DateFormat('dd MMM yyyy, HH:mm');

  // --- WARNA TEMA ---
  static const Color _headerColor = Color(0xFF0E2F60);
  static const Color _accentColor = Color(0xFF3C486B);
  static const Color _cardIndicator = Color(0xFF6C4BA3);

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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal memuat data kegiatan: $e")),
        );
      }
    }
  }

  void _goToDetailKegiatan(Kegiatan kegiatan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailKegiatanScreen(kegiatan: kegiatan),
      ),
    );
  }

  Widget _buildKegiatanCard(Kegiatan kegiatan) {
    String scope = 'Desa';
    if (kegiatan.rt != null) {
      scope = "RT ${kegiatan.rt} / RW ${kegiatan.rw}";
    } else if (kegiatan.rw != null) {
      scope = "RW ${kegiatan.rw}";
    }

    final bool isFinished = kegiatan.tanggalSelesai.isBefore(DateTime.now());
    final Color primaryColor = isFinished ? Colors.grey : _accentColor;
    final Color indicatorColor = isFinished ? Colors.grey : const Color(0xFF0E2F60);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: () => _goToDetailKegiatan(kegiatan), 
        child: Stack(
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
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: primaryColor.withOpacity(0.1),
                    child: Icon(Icons.event_note, color: primaryColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          kegiatan.namaKegiatan,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Waktu: ${_dateFormat.format(kegiatan.tanggalMulai)}",
                          style: TextStyle(
                              fontWeight: FontWeight.w600, color: primaryColor),
                        ),
                        const SizedBox(height: 6),
                        Text("Lokasi: ${kegiatan.lokasi}"),
                        Text(
                          "Lingkup: $scope",
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
                ],
              ),
            ),
            Positioned(
              left: 0,
              top: 8,
              bottom: 8,
              child: Container(
                width: 6,
                decoration: BoxDecoration(
                  color: indicatorColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                    topRight: Radius.circular(6),
                    bottomRight: Radius.circular(6),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 16),
      decoration: const BoxDecoration(
        color: _headerColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                "Daftar Kegiatan Desa",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (query) => _fetchKegiatan(search: query),
                decoration: InputDecoration(
                  hintText: "Cari nama kegiatan...",
                  prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
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
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: _headerColor))
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
                            onRefresh: () =>
                                _fetchKegiatan(search: _searchController.text),
                            color: _accentColor,
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding:
                                  const EdgeInsets.only(top: 8, bottom: 16),
                              itemCount: _kegiatanList.length,
                              itemBuilder: (_, i) {
                                return _buildKegiatanCard(_kegiatanList[i]);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}