import 'package:flutter/material.dart';
import 'package:frontend/models/user_model.dart';
import 'package:frontend/services/api_service.dart';
import 'package:provider/provider.dart';

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
    setState(() {
      _isLoading = true;
    });

    final apiService = context.read<ApiService>();
    try {
      final warga = await apiService.getDetailWarga(widget.wargaAwal.id);
      if (warga != null) {
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

  @override
  Widget build(BuildContext context) {
    
    
    final warga = _wargaDetail ?? widget.wargaAwal;

    return Scaffold(
      appBar: AppBar(
        title: Text(warga.namaLengkap),
        actions: [
          
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchDetailWarga,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    
                    child: Text(
                      warga.namaLengkap[0].toUpperCase(),
                      style: const TextStyle(fontSize: 40),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    warga.namaLengkap,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "NIK: ${warga.nik}",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (_isLoading) ...[
                    const SizedBox(height: 8),
                    const LinearProgressIndicator(),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),

            
            _buildSectionTitle(context, "Data Diri"),
            _buildDetailRow("Tempat Lahir", warga.tempatLahir),
            _buildDetailRow("Tgl. Lahir", warga.tanggalLahir),
            _buildDetailRow(
              "Jenis Kelamin",
              warga.jenisKelamin == 'L' ? "Laki-laki" : "Perempuan",
            ),
            _buildDetailRow("Agama", warga.agama),
            _buildDetailRow("Pekerjaan", warga.pekerjaan),
            _buildDetailRow("Status", warga.statusPerkawinan),
            _buildDetailRow("No. HP", warga.noHp ?? "-"),

            
            const SizedBox(height: 16),
            _buildSectionTitle(context, "Alamat & Domisili"),
            _buildDetailRow("Alamat KTP", warga.alamatKtp),
            _buildDetailRow("RT / RW", "${warga.rt} / ${warga.rw}"),

            
            if (warga.keluarga != null) ...[
              const SizedBox(height: 16),
              _buildSectionTitle(context, "Data Keluarga"),
              _buildDetailRow("No. KK", warga.keluarga!.noKk),
              _buildDetailRow("Status di KK", warga.statusDalamKeluarga),
              _buildDetailRow("Alamat KK", warga.keluarga!.alamat),
            ],

            
            if (warga.user != null) ...[
              const SizedBox(height: 16),
              _buildSectionTitle(context, "Akun Terhubung"),
              _buildDetailRow("Email", warga.user!.email),
              _buildDetailRow("Role", warga.user!.role.toUpperCase()),
            ],
          ],
        ),
      ),
    );
  }

  
  Widget _buildDetailRow(String title, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 4),
          Text(
            value ?? "-", 
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
