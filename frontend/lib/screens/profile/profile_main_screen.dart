import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/state/auth_provider.dart';
import 'package:frontend/models/user_model.dart';
import 'package:frontend/screens/placeholder_screen.dart';
import 'package:intl/intl.dart';
import 'package:frontend/screens/wajah/register_face_screen.dart';
import 'package:frontend/screens/wajah/login_face_screen.dart';
import 'package:frontend/screens/admin/manajemen_iuran_screen.dart';
import 'package:frontend/screens/admin/manajemen_kegiatan_screen.dart';
import 'package:frontend/screens/admin/manajemen_acara_screen.dart';

class ProfileMainScreen extends StatelessWidget {
  const ProfileMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    if (user == null) {
      return const Center(child: Text("Data pengguna tidak ditemukan."));
    }

    final List<Map<String, dynamic>> menuItems = _buildMenuItems(
      user,
      authProvider,
    );

    return Scaffold(
      appBar: AppBar(title: const Text("Profil & Pengaturan")),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildProfileCard(context, user),
          const SizedBox(height: 20),

          Text(
            "Akses Fitur Cepat",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),

          ...menuItems.map((item) => _buildMenuItem(context, item)).toList(),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, User user) {
    final String? balance = user.warga?.wallet?.balance.toStringAsFixed(0);
    final String formattedBalance = balance != null
        ? "Rp ${NumberFormat.currency(locale: 'id', symbol: '', decimalDigits: 0).format(double.parse(balance))}"
        : "";

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
                  if (user.warga != null)
                    Text(
                      "RT ${user.warga!.rt} / RW ${user.warga!.rw}",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  if (balance != null)
                    Text(
                      "Saldo: $formattedBalance",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, Map<String, dynamic> item) {
    final bool isDanger = item['color'] == Colors.red;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(item['icon'] as IconData, color: item['color'] as Color),
        title: Text(
          item['title'] as String,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDanger ? Colors.red : null,
          ),
        ),
        trailing: isDanger
            ? null
            : const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          item['onTap'](context);
        },
      ),
    );
  }

  List<Map<String, dynamic>> _buildMenuItems(
    User user,
    AuthProvider authProvider,
  ) {
    List<Map<String, dynamic>> items = [];

    items.add({
      'title': 'Atur Login Wajah',
      'icon': Icons.face_retouching_natural,
      'color': Colors.blueGrey,
      'onTap': (BuildContext context) => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const RegisterFaceScreen())),
    });

    items.add({
      'title': 'Ganti Password/Profil',
      'icon': Icons.security,
      'color': Colors.blue,
      'onTap': (BuildContext context) => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              const PlaceholderScreen(title: "Ganti Password/Profil"),
        ),
      ),
    });

    if (user.role != 'warga') {
      items.add({
        'title': 'Laporan Keuangan',
        'icon': Icons.account_balance_wallet,
        'color': Colors.green,
        'onTap': (BuildContext context) => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const PlaceholderScreen(title: "Laporan Keuangan"),
          ),
        ),
      });
      items.add({
        'title': 'Manajemen Iuran',
        'icon': Icons.receipt_long,
        'color': Colors.orange,
        'onTap': (BuildContext context) => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ManajemenIuranScreen())),
      });
      items.add({
        'title': 'Manajemen Kegiatan',
        'icon': Icons.event,
        'color': Colors.purple,
        'onTap': (BuildContext context) => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ManajemenKegiatanScreen()),
        ),
      });
      items.add({
        'title': 'Manajemen Acara',
        'icon': Icons.celebration,
        'color': Colors.redAccent,
        'onTap': (BuildContext context) => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ManajemenAcaraScreen())),
      });
    }

    if (user.role == 'warga') {
      items.add({
        'title': 'Data Keluarga Saya',
        'icon': Icons.family_restroom,
        'color': Colors.indigo,
        'onTap': (BuildContext context) => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                const PlaceholderScreen(title: "Data Keluarga Saya"),
          ),
        ),
      });
    }

    items.add({
      'title': 'Logout',
      'icon': Icons.logout,
      'color': Colors.red,
      'onTap': (BuildContext context) async {
        await authProvider.logout();
        if (context.mounted) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      },
    });

    return items;
  }
}
