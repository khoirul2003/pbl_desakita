import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:frontend/state/auth_provider.dart';
import 'package:frontend/models/user_model.dart';
import 'package:frontend/models/wallet_models.dart';
import 'package:frontend/screens/placeholder_screen.dart'; // FIX: Sudah ada di impor

// --- DEFINISI WARNA PROSCAN ---
const Color _primaryColor = Color(0xFF0E2F60); // Biru Tua
const Color _backgroundColor = Color(0xFFF5F5F5); // Abu-abu muda
const Color _accentColor = Color(0xFF3C486B); // Aksen Biru/Abu
const Color _successColor = Color(0xFF28A745); // Hijau
const Color _dangerColor = Colors.red; // Didefinisikan di sini

class DetailProfileScreen extends StatelessWidget {
  const DetailProfileScreen({super.key});

  // --- WIDGET BANTUAN: DETAIL ROW ---
  Widget _buildDetailRow(String title, String value, {IconData? icon, Color valueColor = Colors.black87}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) Icon(icon, color: _primaryColor, size: 20),
          if (icon != null) const SizedBox(width: 12),
          SizedBox(
            width: 120,
            child: Text(
              title,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600, 
                color: valueColor, 
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET BANTUAN: KARTU DETAIL DENGAN SHADOW PROSCAN ---
  Widget _buildCardSection({required BuildContext context, required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: _primaryColor, 
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            children: children,
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    if (user?.warga == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Detail Profil"), backgroundColor: _primaryColor, foregroundColor: Colors.white),
        body: const Center(child: Text("Data Warga tidak lengkap atau belum dimuat.")),
      );
    }

    final warga = user!.warga!;
    final wallet = warga.wallet;
    final formattedBalance = wallet != null
        ? "Rp ${NumberFormat.currency(locale: 'id', symbol: '', decimalDigits: 0).format(wallet.balance)}"
        : "N/A";
        
    final roleText = user.role.toUpperCase();

    // Menggunakan Field yang Benar dari Model Warga
    final String noHpText = warga.noHp ?? "Belum diisi";
    final String alamatText = warga.alamatKtp ?? "Belum diisi";


    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text("Detail Profil"),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- KARTU PROFIL HEADER (Ringkasan) ---
            _buildCardSection(
              context: context,
              title: "Informasi Dasar",
              children: [
                _buildDetailRow("Nama Lengkap", warga.namaLengkap),
                _buildDetailRow("Email", user.email, icon: Icons.email),
                _buildDetailRow("Nomor Telepon", noHpText, icon: Icons.phone), 
                _buildDetailRow("Role Pengguna", roleText, valueColor: roleText == 'ADMIN' ? _dangerColor : _primaryColor),
              ],
            ),

            // --- KARTU LINGKUP WILAYAH ---
            _buildCardSection(
              context: context,
              title: "Lingkup Wilayah",
              children: [
                _buildDetailRow("Alamat KTP", alamatText, icon: Icons.home), 
                _buildDetailRow("RT", warga.rt),
                _buildDetailRow("RW", warga.rw),
              ],
            ),

            // --- KARTU DESAPAY WALLET ---
            _buildCardSection(
              context: context,
              title: "Detail Desapay",
              children: [
                _buildDetailRow("No. Akun", wallet?.desapayAccountNumber ?? "Belum terdaftar", icon: Icons.credit_card),
                _buildDetailRow("Saldo Saat Ini", formattedBalance, valueColor: _successColor),
              ],
            ),

            // --- MENGHILANGKAN TOMBOL EDIT PROFIL ---
            const SizedBox(height: 40),
            
            /*
            // Tombol Edit Profil yang Dihilangkan
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const PlaceholderScreen(title: "Halaman Edit Profil"), 
                ));
              },
              icon: const Icon(Icons.edit, color: Colors.white),
              label: const Text("UBAH PROFIL", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            */
            const SizedBox(height: 20),
            // --- AKHIR PENGHILANGAN ---
          ],
        ),
      ),
    );
  }
}