import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:frontend/models/user_model.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/state/auth_provider.dart';
import 'package:frontend/screens/admin/detail_warga_screen.dart';

class ManajemenWargaRtRwScreen extends StatefulWidget {
  const ManajemenWargaRtRwScreen({super.key});

  @override
  State<ManajemenWargaRtRwScreen> createState() =>
      _ManajemenWargaRtRwScreenState();
}

class _ManajemenWargaRtRwScreenState extends State<ManajemenWargaRtRwScreen> {
  // =========================
  // STATE
  // =========================
  List<Warga> _wargaList = [];
  bool _isLoading = true;
  String _errorMessage = "";

  final TextEditingController _searchController = TextEditingController();

  String? _userRole;
  String? _userRT;
  String? _userRW;

  static const Color _primaryColor = Color(0xFF0E2F60);
  static const Color _cardIndicator = _primaryColor;

  // =========================
  // LIFECYCLE
  // =========================
  @override
  void initState() {
    super.initState();
    _initializeUserAndFetchWarga();
  }

  // =========================
  // INIT & API
  // =========================
  void _initializeUserAndFetchWarga() {
    final user = context.read<AuthProvider>().user;

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
      setState(() => _isLoading = false);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    final apiService = context.read<ApiService>();

    final String? filterRw = _userRW;
    final String? filterRt = (_userRole == 'rt') ? _userRT : null;

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
        _errorMessage = "Gagal memuat data warga di wilayah Anda.";
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal memuat data warga: $e")),
        );
      }
    }
  }

  void _onSearchChanged(String query) {
    _fetchWarga(search: query);
  }

  // =========================
  // NAVIGATION
  // =========================
  void _goToDetail(Warga warga) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DetailWargaScreen(wargaAwal: warga),
      ),
    );
  }

  // =========================
  // UI COMPONENT
  // =========================
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
        color: _primaryColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Text(
            "Manajemen Warga $wilayah",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
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
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _primaryColor),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(child: Text(_errorMessage));
    }

    if (_wargaList.isEmpty) {
      return Center(
        child: Text(
          _searchController.text.isEmpty
              ? "Tidak ada data warga di wilayah Anda."
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
        itemBuilder: (context, index) {
          return _buildWargaCard(_wargaList[index]);
        },
      ),
    );
  }

  Widget _buildWargaCard(Warga warga) {
    final String inisial =
        warga.namaLengkap.isNotEmpty ? warga.namaLengkap[0].toUpperCase() : "?";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: () => _goToDetail(warga),
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: _primaryColor.withOpacity(0.1),
                    child: Text(
                      inisial,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _primaryColor,
                      ),
                    ),
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
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: Colors.grey,
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

  // =========================
  // BUILD
  // =========================
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
