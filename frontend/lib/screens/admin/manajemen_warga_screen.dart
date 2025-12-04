import 'package:flutter/material.dart';
import 'package:frontend/models/user_model.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/screens/admin/tambah_warga_screen.dart';
import 'package:frontend/screens/admin/detail_warga_screen.dart';
import 'package:frontend/screens/admin/edit_warga_screen.dart';
import 'package:provider/provider.dart';

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

  // WARNA AKSES (DIRENAME AGAR JELAS, TAPI NILAI TETAP BIRU TUA)
  static const Color _primaryColor = Color(0xFF0e2f60); 
  // WARNA INDIKATOR DIUBAH KE PRIMARY COLOR
  static const Color _cardIndicator = _primaryColor; 

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

    final apiService = context.read<ApiService>();

    try {
      final warga = await apiService.getManajemenWarga(search: search);
      setState(() {
        _wargaList = warga;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Gagal memuat data: $e";
      });
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Gagal memuat data warga: $e")));
      }
    }
  }

  void _onSearchChanged(String query) => _fetchWarga(search: query);

  void _tambahWarga() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const TambahWargaScreen(),
        fullscreenDialog: true,
      ),
    );
    if (result == true) _fetchWarga(search: _searchController.text);
  }

  void _goToDetail(Warga warga) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DetailWargaScreen(wargaAwal: warga)),
    );
  }

  Future<void> _goToEditWarga(Warga warga) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditWargaScreen(warga: warga),
        fullscreenDialog: true,
      ),
    );
    if (result == true) _fetchWarga(search: _searchController.text);
  }

  Future<void> _deleteWarga(Warga warga) async {
    final bool? confirmed = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Hapus Warga"),
        content: Text("Apakah Anda yakin ingin menghapus ${warga.namaLengkap}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final apiService = context.read<ApiService>();
      try {
        final success = await apiService.deleteWarga(warga.id);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("${warga.namaLengkap} berhasil dihapus."), backgroundColor: Colors.green),
          );
          _fetchWarga(search: _searchController.text);
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

  // --- HEADER HALAMAN WARGA YANG DIMODIFIKASI ---
  Widget _buildHeader() {
    return Container(
      // Padding atas disesuaikan: MediaQuery.of(context).padding.top + 8
      padding: EdgeInsets.fromLTRB(
        20, 
        MediaQuery.of(context).padding.top + 8, // Mengambil padding sistem dan menambahkan 8
        20, 
        16
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0E2F60), // Warna utama header
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Judul halaman
          Center(
            child: const Text(
              "Halaman Warga",
              style: TextStyle(
                color: Colors.white,
                // Ukuran diubah menjadi 20 (sama dengan Profil & Pengaturan)
                fontSize: 20, 
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Search
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (query) => _fetchWarga(search: query),
              decoration: InputDecoration(
                hintText: "Cari nama atau NIK...",
                prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
            ),
          ),
          const SizedBox(height: 14),
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

  // BODY
  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: _primaryColor));
    if (_errorMessage.isNotEmpty) return Center(child: Text("Error: $_errorMessage"));

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
      color: _primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 12, bottom: 24),
        itemCount: _wargaList.length,
        itemBuilder: (context, index) => _buildWargaCard(_wargaList[index]),
      ),
    );
  }

  // CARD WARGA
  Widget _buildWargaCard(Warga warga) {
    final String inisial = warga.namaLengkap.isNotEmpty ? warga.namaLengkap[0].toUpperCase() : "?";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: () => _goToDetail(warga),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 6))],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    // Menggunakan _primaryColor untuk warna latar belakang avatar
                    backgroundColor: _primaryColor.withOpacity(0.1),
                    child: Text(
                      inisial, 
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _primaryColor)
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(warga.namaLengkap, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text("NIK: ${warga.nik}", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                        const SizedBox(height: 4),
                        Text("RW: ${warga.rw} | RT: ${warga.rt}", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.grey),
                    onSelected: (value) {
                      if (value == 'edit') _goToEditWarga(warga);
                      if (value == 'delete') _deleteWarga(warga);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(children: [Icon(Icons.edit, size: 20, color: _primaryColor), SizedBox(width: 8), Text("Edit")]),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 20), SizedBox(width: 8), Text("Hapus", style: TextStyle(color: Colors.red))]),
                      ),
                    ],
                  )
                ],
              ),
            ),
            // INDIKATOR SISI KIRI MENGGUNAKAN _cardIndicator (YANG SEKARANG _primaryColor)
            Positioned(
              left: 0,
              top: 8,
              bottom: 8,
              child: Container(
                width: 6,
                decoration: BoxDecoration(
                  color: _cardIndicator, // Menggunakan warna primary
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12), topRight: Radius.circular(6), bottomRight: Radius.circular(6)),
                ),
              ),
            ),
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