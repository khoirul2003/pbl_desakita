// screens/warga/acara_warga_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Wajib ada untuk DateFormat
import 'package:frontend/services/api_service.dart';
import 'package:frontend/models/acara_model.dart'; 
// Pastikan path ini benar (sesuaikan jika lokasi DetailAcaraScreen berbeda)
import 'package:frontend/screens/warga/Detail_Acara_Screen.dart'; 

const Color _primaryColor = Color(0xFF0E2F60);
const Color _accentColor = Color(0xFF3C486B);

class AcaraWargaScreen extends StatefulWidget {
  const AcaraWargaScreen({super.key});

  @override
  State<AcaraWargaScreen> createState() => _AcaraWargaScreenState();
}

class _AcaraWargaScreenState extends State<AcaraWargaScreen> {
  List<Acara> _acaraList = [];
  bool _isLoading = true;
  String _errorMessage = "";
  final TextEditingController _searchController = TextEditingController();

  // Format tanggal dan waktu yang akan ditampilkan
  final DateFormat _dateTimeFormatter = DateFormat('dd MMM yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _fetchAcara();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAcara({String? search}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    final apiService = context.read<ApiService>();
    try {
      // Perlu diingat: getManajemenAcara harus mengembalikan List<Acara>
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
    }
  }

  void _onSearchChanged(String query) {
    // Implementasi debounce jika diperlukan, sementara panggil langsung
    _fetchAcara(search: query);
  }

  // Header Disederhanakan (Tidak ada perubahan)
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
              "Daftar Acara Warga",
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
                hintText: "Cari nama acara...",
                prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcaraCard(Acara acara) {
    // Tentukan scope RT/RW untuk ditampilkan
    String scope = 'Desa';
    if (acara.rt != null || acara.rw != null) {
      scope = "RT ${acara.rt ?? '-'} / RW ${acara.rw ?? '-'}";
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector( // <-- DITAMBAHKAN: GestureDetector untuk navigasi
        onTap: () {
          // Navigasi ke DetailAcaraScreen dan lewati objek acara
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (ctx) => DetailAcaraScreen(
                acara: acara, // <-- Melewatkan objek Acara lengkap
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
              const Icon(Icons.event, color: _primaryColor, size: 30),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      acara.namaAcara, 
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Mulai: ${_dateTimeFormatter.format(acara.tanggalMulai)}",
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    Text(
                      "Selesai: ${_dateTimeFormatter.format(acara.tanggalSelesai)}",
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Lokasi: ${acara.lokasi} ($scope)", 
                      style: TextStyle(color: _accentColor, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              // Indikator bahwa card bisa diklik
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
      
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(_errorMessage, textAlign: TextAlign.center, style: TextStyle(color: Colors.red)),
        ),
      );
    }
      
    if (_acaraList.isEmpty) {
      return Center(
        child: Text(
          _searchController.text.isEmpty
              ? "Tidak ada acara yang tersedia saat ini."
              : "Tidak ditemukan acara untuk '${_searchController.text}'.",
          style: const TextStyle(color: Colors.black54),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchAcara(search: _searchController.text),
      color: _primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 12, bottom: 24),
        itemCount: _acaraList.length,
        itemBuilder: (context, index) => _buildAcaraCard(_acaraList[index]),
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