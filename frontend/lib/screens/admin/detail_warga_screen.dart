import 'package:flutter/material.dart';
import 'package:frontend/models/user_model.dart';
import 'package:frontend/services/api_service.dart';
import 'package:provider/provider.dart';

import 'package:frontend/screens/admin/edit_warga_screen.dart';

const Color _primaryColor = Color(0xFF0E2F60);
const Color _accentColor = Color(0xFF3C486B);
const Color _backgroundColor = Color(0xFFF5F5F5);

class DetailWargaScreen extends StatefulWidget {
  final Warga wargaAwal;

  const DetailWargaScreen({super.key, required this.wargaAwal});

  @override
  State<DetailWargaScreen> createState() => _DetailWargaScreenState();
}

class _DetailWargaScreenState extends State<DetailWargaScreen> {
  Warga? _wargaDetail;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _wargaDetail = widget.wargaAwal;
    _fetchDetailWarga();
  }

  Future<void> _fetchDetailWarga() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    final apiService = context.read<ApiService>();
    try {
      final warga = await apiService.getDetailWarga(widget.wargaAwal.id);
      if (warga != null && mounted) {
        setState(() {
          _wargaDetail = warga;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Gagal memuat detail: $e")));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _goToEditWarga() async {
    final Warga currentWarga = _wargaDetail ?? widget.wargaAwal;

    final bool? result = await Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) =>
            EditWargaScreen(warga: currentWarga),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeOut;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );

    if (result == true) {
      _fetchDetailWarga();
    }
  }

  Widget _buildCustomHeader(BuildContext context, String title, Warga warga) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      decoration: const BoxDecoration(
        color: _primaryColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),

            onPressed: _goToEditWarga,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(Warga warga) {
    return _buildCardWrapper(
      child: Center(
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: _primaryColor.withOpacity(0.1),
              child: Text(
                warga.namaLengkap[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 36,
                  color: _primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              warga.namaLengkap,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _accentColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "NIK: ${warga.nik}",
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 20),
    );
  }

  Widget _buildCardWrapper({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(16),
  }) {
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
          ),
        ],
      ),
      padding: padding,
      child: child,
    );
  }

  @override
  Widget _buildDetailRow(
    String title,
    String? value, {
    bool showDivider = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 16),

              Expanded(
                child: Text(
                  value ?? "-",
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          if (showDivider)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Divider(height: 1, color: Colors.grey[200]),
            ),
        ],
      ),
    );
  }

  @override
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0, left: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: _primaryColor,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final warga = _wargaDetail ?? widget.wargaAwal;

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Column(
        children: [
          _buildCustomHeader(context, "Detail Warga", warga),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchDetailWarga,
              color: _primaryColor,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 20,
                ),
                children: [
                  _buildProfileCard(warga),

                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(color: _primaryColor),
                      ),
                    ),

                  _buildSectionTitle(context, "Data Diri"),
                  _buildCardWrapper(
                    child: Column(
                      children: [
                        _buildDetailRow("Tempat Lahir", warga.tempatLahir),
                        _buildDetailRow("Tgl. Lahir", warga.tanggalLahir),
                        _buildDetailRow(
                          "Jenis Kelamin",
                          warga.jenisKelamin == 'L' ? "Laki-laki" : "Perempuan",
                        ),
                        _buildDetailRow("Agama", warga.agama),
                        _buildDetailRow("Pekerjaan", warga.pekerjaan),
                        _buildDetailRow("Status", warga.statusPerkawinan),
                        _buildDetailRow(
                          "No. HP",
                          warga.noHp ?? "-",
                          showDivider: false,
                        ),
                      ],
                    ),
                  ),

                  _buildSectionTitle(context, "Alamat & Domisili"),
                  _buildCardWrapper(
                    child: Column(
                      children: [
                        _buildDetailRow("Alamat KTP", warga.alamatKtp),
                        _buildDetailRow(
                          "RT / RW",
                          "${warga.rt} / ${warga.rw}",
                          showDivider: false,
                        ),
                      ],
                    ),
                  ),

                  if (warga.keluarga != null) ...[
                    _buildSectionTitle(context, "Data Keluarga"),
                    _buildCardWrapper(
                      child: Column(
                        children: [
                          _buildDetailRow("No. KK", warga.keluarga!.noKk),
                          _buildDetailRow(
                            "Status di KK",
                            warga.statusDalamKeluarga,
                          ),
                          _buildDetailRow(
                            "Alamat KK",
                            warga.keluarga!.alamat,
                            showDivider: false,
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (warga.user != null) ...[
                    _buildSectionTitle(context, "Akun Terhubung"),
                    _buildCardWrapper(
                      child: Column(
                        children: [
                          _buildDetailRow("Email", warga.user!.email),
                          _buildDetailRow(
                            "Role",
                            warga.user!.role.toUpperCase(),
                            showDivider: false,
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
