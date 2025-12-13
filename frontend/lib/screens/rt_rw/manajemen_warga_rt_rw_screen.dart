import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/models/user_model.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/state/auth_provider.dart';
import 'package:frontend/screens/admin/tambah_warga_screen.dart'; 
import 'package:frontend/screens/admin/detail_warga_screen.dart';
import 'package:frontend/screens/admin/edit_warga_screen.dart';

class ManajemenWargaRtRwScreen extends StatefulWidget {
  const ManajemenWargaRtRwScreen({super.key});

  @override
  State<ManajemenWargaRtRwScreen> createState() => _ManajemenWargaRtRwScreenState();
}

class _ManajemenWargaRtRwScreenState extends State<ManajemenWargaRtRwScreen> {
  List<Warga> _wargaList = [];
  bool _isLoading = true;
  String _errorMessage = "";
  final TextEditingController _searchController = TextEditingController();

  String? _userRole;
  String? _userRT;
  String? _userRW;

  static const Color _primaryColor = Color(0xFF0e2f60);
  static const Color _cardIndicator = _primaryColor;

  @override
  void initState() {
    super.initState();
    _initializeUserAndFetchWarga();
  }

  void _initializeUserAndFetchWarga() {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    
    if (user != null && user.warga != null) {
      _userRole = user.role;
      _userRT = user.warga!.rt;
      _userRW = user.warga!.rw;
      _fetchWarga();
    } else {
      setState(() {
        _errorMessage = "Akses ditolak atau data wilayah tidak ditemukan.";
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchWarga({String? search}) async {
    if (_userRole == null || _userRW == null) {
      setState(() {
        _isLoading = false;
        return;
      });
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    final apiService = context.read<ApiService>();

    // Logika Pemfilteran:
    // 1. RW akan mengirim filter RW-nya saja.
    // 2. RT akan mengirim filter RT dan RW-nya.
    String? filterRw = _userRW;
    String? filterRt = (_userRole == 'rt') ? _userRT : null; // Hanya kirim RT jika rolenya 'rt'

    try {
      final warga = await apiService.getManajemenWarga(
        search: search,
        rt: filterRt, 
        rw: filterRw,
      );
      setState(() {
        _wargaList = warga;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Gagal memuat data warga di wilayah Anda: $e";
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Gagal memuat data warga: $e")));
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
        content: Text(
          "Apakah Anda yakin ingin menghapus ${warga.namaLengkap}? Tindakan ini tidak dapat dibatalkan.",
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
      ),
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


  Widget _buildHeader() {
    String wilayah = "";
    if (_userRole == 'rt' && _userRT != null && _userRW != null) {
      wilayah = "RT $_userRT / RW $_userRW";
    } else if (_userRole == 'rw' && _userRW != null) {
      wilayah = "RW $_userRW";
    }

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 8,
        20,
        16,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0E2F60),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              "Manajemen Warga $wilayah", 
              style: const TextStyle(
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
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: "Cari nama atau NIK...",
                prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
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

  Widget _buildBody() {
    if (_isLoading)
      return const Center(
        child: CircularProgressIndicator(color: _primaryColor),
      );
    if (_errorMessage.isNotEmpty)
      return Center(child: Text("Error: $_errorMessage"));

    if (_wargaList.isEmpty) {
      return Center(
        child: Text(
          _searchController.text.isEmpty
              ? "Tidak ada data warga di wilayah Anda."
              : "Tidak ada kecocokan untuk '${_searchController.text}' di wilayah Anda.",
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

  Widget _buildWargaCard(Warga warga) {
    final String inisial = warga.namaLengkap.isNotEmpty
        ? warga.namaLengkap[0].toUpperCase()
        : "?";

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
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: _primaryColor.withOpacity(0.1),
                    backgroundImage:
                        warga.fotoKtp != null && warga.fotoKtp!.isNotEmpty
                        ? NetworkImage(warga.fotoKtp!)
                        : null,
                    child: warga.fotoKtp == null || warga.fotoKtp!.isEmpty
                        ? Text(
                            inisial,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: _primaryColor,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          warga.namaLengkap,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "NIK: ${warga.nik}",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "RW: ${warga.rw} | RT: ${warga.rt}",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // PopUpMenuButton (Edit dan Hapus)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.grey),
                    onSelected: (value) {
                      if (value == 'edit') _goToEditWarga(warga);
                      if (value == 'delete') _deleteWarga(warga);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20, color: _primaryColor),
                            SizedBox(width: 8),
                            Text("Edit"),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red, size: 20),
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
            Positioned(
              left: 0,
              top: 8,
              bottom: 8,
              child: Container(
                width: 6,
                decoration: BoxDecoration(
                  color: _cardIndicator,
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