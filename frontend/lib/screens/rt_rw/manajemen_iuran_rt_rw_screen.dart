import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/models/iuran_model.dart';
import 'package:frontend/state/auth_provider.dart';
// Asumsi: masih menggunakan screen CRUD Admin, 
// namun di backend harus ada validasi RT/RW hanya bisa mengedit iuran di wilayahnya.
import 'package:frontend/screens/admin/tambah_iuran_screen.dart';
import 'package:frontend/screens/admin/edit_iuran_screen.dart';
import 'package:frontend/screens/admin/detail_iuran_screen.dart'; 


// --- DEFINISI WARNA TEMA ---
const Color _primaryColor = Color(0xFF0E2F60);
const Color _accentColor = Color(0xFF3C486B);
const Color _cardIndicator = _primaryColor;


class ManajemenIuranRtRwScreen extends StatefulWidget {
  const ManajemenIuranRtRwScreen({super.key});

  @override
  State<ManajemenIuranRtRwScreen> createState() => _ManajemenIuranRtRwScreenState();
}

class _ManajemenIuranRtRwScreenState extends State<ManajemenIuranRtRwScreen> {
  List<Iuran> _iuranList = [];
  bool _isLoading = true;
  String _errorMessage = "";
  final TextEditingController _searchController = TextEditingController();

  String? _userRole;
  String? _userRT;
  String? _userRW;

  final NumberFormat _rupiahFormatter = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _initializeUserAndFetchIuran();
  }

  void _initializeUserAndFetchIuran() {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    
    if (user != null && user.warga != null) {
      _userRole = user.role;
      _userRT = user.warga!.rt;
      _userRW = user.warga!.rw;
      _fetchIuran();
    } else {
      setState(() {
        _errorMessage = "Akses ditolak atau data wilayah tidak ditemukan.";
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchIuran({String? search}) async {
    if (!mounted) return;
    
    if (_userRole == null || _userRW == null) {
       if (!mounted) return;
       setState(() {
         _isLoading = false;
       });
       return;
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
      final iuran = await apiService.getManajemenIuran(
        search: search,
        rt: filterRt,
        rw: filterRw,
      );
      
      if (!mounted) return;
      setState(() {
        _iuranList = iuran;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = "Gagal memuat data iuran di wilayah Anda";
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal memuat data iuran: $e")),
        );
      }
    }
  }

  void _tambahIuran() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const TambahIuranScreen(),
        fullscreenDialog: true,
      ),
    );
    if (result == true) {
      _fetchIuran(search: _searchController.text);
    }
  }

  void _editIuran(Iuran iuran) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditIuranScreen(iuran: iuran),
        fullscreenDialog: true,
      ),
    );
    if (result == true) {
      _fetchIuran(search: _searchController.text);
    }
  }

  void _goToDetailIuran(Iuran iuran) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DetailIuranScreen(iuran: iuran),
      ),
    );
    _fetchIuran(search: _searchController.text);
  }


  Future<void> _deleteIuran(Iuran iuran) async {
    final bool? confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Iuran"),
        content: Text(
            "Apakah Anda yakin ingin menghapus jenis iuran '${iuran.namaIuran}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Hapus",
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final apiService = context.read<ApiService>();
      try {
        final success = await apiService.deleteIuran(iuran.id);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("${iuran.namaIuran} berhasil dihapus."),
              backgroundColor: Colors.green,
            ),
          );
          _fetchIuran(search: _searchController.text);
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
        16
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
          Center(
            child: Text(
              "Manajemen Iuran $wilayah", 
              style: const TextStyle(
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
              onChanged: (query) => _fetchIuran(search: query),
              decoration: InputDecoration(
                hintText: "Cari jenis iuran...",
                prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
            ),
          ),
          const SizedBox(height: 14),
          
          // Tombol Tambah Iuran
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _tambahIuran,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text("Tambah Iuran"),
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
  
  Widget _buildIuranCard(Iuran iuran) {
    String scope = 'Desa';
    if (iuran.rt != null) {
      scope = "RT ${iuran.rt} / RW ${iuran.rw}";
    } else if (iuran.rw != null) {
      scope = "RW ${iuran.rw}";
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: () {
          _goToDetailIuran(iuran);
        },
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
                    backgroundColor: _accentColor.withOpacity(0.1), 
                    child: Icon(
                      iuran.tipe == 'PER_KELUARGA'
                          ? Icons.house
                          : Icons.person,
                      color: _accentColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          iuran.namaIuran,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _rupiahFormatter.format(iuran.jumlah),
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, color: _accentColor),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${iuran.tipe.replaceAll('_', ' ')} • $scope',
                          style: TextStyle(
                              color: Colors.grey[600], fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.grey),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editIuran(iuran);
                      } else if (value == 'delete') {
                        _deleteIuran(iuran);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20, color: _primaryColor),
                            SizedBox(width: 8),
                            Text("Edit Jenis"),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Text("Hapus Jenis",
                                style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  )
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
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading)
      return const Center(child: CircularProgressIndicator(color: _primaryColor));
    if (_errorMessage.isNotEmpty)
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(_errorMessage),
        ),
      );

    if (_iuranList.isEmpty) {
      return Center(
        child: Text(
          _searchController.text.isEmpty
              ? 'Belum ada jenis iuran yang terdaftar di wilayah ini.'
              : 'Tidak ditemukan jenis iuran di wilayah ini.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchIuran(search: _searchController.text),
      color: _primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 12, bottom: 24),
        itemCount: _iuranList.length,
        itemBuilder: (context, index) => _buildIuranCard(_iuranList[index]),
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
            child: _buildBody(),
          ),
        ],
      ),
    );
  }
}