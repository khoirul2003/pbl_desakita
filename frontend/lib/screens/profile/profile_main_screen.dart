import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/state/auth_provider.dart';
import 'package:frontend/models/user_model.dart';
import 'package:frontend/screens/placeholder_screen.dart';
import 'package:frontend/screens/wajah/register_face_screen.dart'; // Untuk Atur Wajah
import 'package:frontend/screens/wajah/login_face_screen.dart'; // Untuk Pindah ke Login Wajah

class ProfileMainScreen extends StatelessWidget {
  const ProfileMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    if (user == null) {
      return const Center(child: Text("Data pengguna tidak ditemukan."));
    }

    // List menu yang muncul di kartu
    final List<Map<String, dynamic>> menuItems = _buildMenuItems(user);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil & Pengaturan"),
        actions: [
          // Tombol Logout di AppBar
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.logout();
              if (context.mounted) {
                // Kembali ke login screen (dihandle oleh main.dart)
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- Bagian Atas: Card Profil (Foto, Nama, Role) ---
          _buildProfileCard(context, user),
          const SizedBox(height: 20),

          // --- Bagian Bawah: List Menu ---
          Text(
            "Akses Fitur Cepat",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          // Mapping list menu ke widget ListTiles
          ...menuItems.map((item) => _buildMenuItem(context, item)).toList(),
        ],
      ),
    );
  }

  // Helper untuk membuat Card Profil di bagian atas
  Widget _buildProfileCard(BuildContext context, User user) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                user.warga?.namaLengkap.isNotEmpty == true
                    ? user.warga!.namaLengkap[0].toUpperCase()
                    : user.email[0].toUpperCase(),
                style: const TextStyle(fontSize: 36, color: Colors.white),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.warga?.namaLengkap ?? "Pengguna Desa",
                    style: Theme.of(context).textTheme.headlineSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    "Role: ${user.role.toUpperCase()}",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  Text(
                    user.warga != null
                        ? "RT ${user.warga!.rt} / RW ${user.warga!.rw}"
                        : user.email,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper untuk membuat setiap item list menu
  Widget _buildMenuItem(BuildContext context, Map<String, dynamic> item) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(item['icon'] as IconData, color: item['color'] as Color),
        title: Text(item['title'] as String),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          if (item['onTap'] != null) {
            item['onTap'](context);
          } else {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PlaceholderScreen(title: item['title']),
              ),
            );
          }
        },
      ),
    );
  }

  // Helper untuk membuat list menu berdasarkan role
  List<Map<String, dynamic>> _buildMenuItems(User user) {
    List<Map<String, dynamic>> items = [];

    // --- Menu Umum ---
    items.add({
      'title': 'Atur Login Wajah',
      'icon': Icons.face_retouching_natural,
      'color': Colors.blueGrey,
      'onTap': (BuildContext context) => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const RegisterFaceScreen())),
    });

    // --- Menu Manajemen (Hanya untuk Admin/RT/RW) ---
    // Di sini menu yang sebelumnya ada di BottomBar dipindahkan
    if (user.role != 'warga') {
      items.add({
        'title': 'Laporan Keuangan',
        'icon': Icons.account_balance_wallet,
        'color': Colors.green,
      });
      items.add({
        'title': 'Manajemen Iuran',
        'icon': Icons.receipt_long,
        'color': Colors.orange,
      });
      items.add({
        'title': 'Manajemen Kegiatan',
        'icon': Icons.event,
        'color': Colors.purple,
      });
      items.add({
        'title': 'Manajemen Acara',
        'icon': Icons.celebration,
        'color': Colors.redAccent,
      });
    }

    // --- Menu Khusus Warga ---
    if (user.role == 'warga') {
      items.add({
        'title': 'Data Keluarga Saya',
        'icon': Icons.family_restroom,
        'color': Colors.indigo,
        // TODO: Anda bisa menambahkan logika onTap di sini untuk ke Detail Keluarga
      });
    }

    return items;
  }
}
