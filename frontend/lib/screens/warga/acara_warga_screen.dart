import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/models/acara_model.dart';
import 'package:frontend/screens/admin/detail_acara_screen.dart'; 


// --- DEFINISI WARNA TEMA ---
const Color _primaryColor = Color(0xFF0E2F60);
const Color _accentColor = Color(0xFF3C486B);
const Color _backgroundColor = Color(0xFFF5F5F5);
const Color _eventColor = Colors.redAccent;
const Color _finishedColor = Colors.grey;
const Color _upcomingColor = Color(0xFF28A745);

class AcaraWargaScreen extends StatefulWidget {
  const AcaraWargaScreen({super.key});

  @override
  State<AcaraWargaScreen> createState() =>
      _AcaraWargaScreenState();
}

class _AcaraWargaScreenState extends State<AcaraWargaScreen> {
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

  void _goToDetailAcara(Acara acara) {
    Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DetailAcaraScreen(acara: acara), 
        ),
      );
  }

  Widget _buildCardWrapper({required Widget child, EdgeInsets padding = const EdgeInsets.all(16)}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16, 
            offset: const Offset(0, 6),
          )
        ],
      ),
      padding: padding,
      child: child,
    );
  }

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
    final Color statusColor = isFinished ? _finishedColor : _upcomingColor; 

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: () => _goToDetailAcara(acara),
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
                  const Padding(
                    padding: EdgeInsets.only(top: 16.0),
                    child: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
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

  Widget _buildHeader() {
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(
            child: Text(
              "Daftar Acara Desa",
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
          const SizedBox(height: 4),
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