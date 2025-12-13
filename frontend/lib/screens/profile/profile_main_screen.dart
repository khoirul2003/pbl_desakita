import 'package:flutter/material.dart';
import 'package:frontend/screens/profile/profile_edit_screen.dart';
import 'package:provider/provider.dart';
import 'package:frontend/state/auth_provider.dart';
import 'package:frontend/models/user_model.dart';
import 'package:frontend/screens/placeholder_screen.dart';
import 'package:intl/intl.dart';
import 'package:frontend/screens/wajah/register_face_screen.dart';
import 'package:frontend/screens/admin/manajemen_keuangan_screen.dart';
import 'package:frontend/screens/admin/manajemen_acara_screen.dart';

const Color _primaryColor = Color(0xFF0E2F60);
const Color _accentColor = Color(0xFF3C486B);
const Color _backgroundColor = Color(0xFFF5F5F5);
const Color _successColor = Color(0xFF28A745);

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
      backgroundColor: _backgroundColor,
      body: Column(
        children: [
          _buildCustomHeader(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 20.0,
              ),
              children: [
                _buildProfileCard(context, user),
                const SizedBox(height: 30),

                Text(
                  "Akses Fitur Cepat",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: _primaryColor,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 10),

                _buildCardWrapper(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: menuItems.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return Column(
                        children: [
                          _buildMenuItem(context, item),

                          if (index < menuItems.length - 1)
                            const Divider(
                              height: 1,
                              thickness: 1,
                              indent: 20,
                              endIndent: 20,
                            ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
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

  Widget _buildCustomHeader(BuildContext context) {
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Profil & Pengaturan",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, User user) {
    return _buildCardWrapper(
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: _primaryColor.withOpacity(0.1),
            backgroundImage: user.warga?.fotoKtp?.isNotEmpty == true
                ? NetworkImage(user.warga!.fotoKtp!) // Foto profil dari URL
                : null,
            child:
                user.warga?.fotoKtp?.isEmpty ??
                    true // Cek jika foto KTP kosong
                ? Text(
                    user.warga?.namaLengkap.isNotEmpty == true
                        ? user.warga!.namaLengkap[0].toUpperCase()
                        : user.email[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 30,
                      color: _primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null, // Jangan tampilkan teks jika ada foto profil
          ),

          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.warga?.namaLengkap ?? "Pengguna Desa",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: _primaryColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "Role: ${user.role.toUpperCase()}",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (user.warga != null)
                  Text(
                    "RT ${user.warga!.rt} / RW ${user.warga!.rw}",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, Map<String, dynamic> item) {
    final bool isDanger = item['color'] == Colors.red;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Icon(item['icon'] as IconData, color: item['color'] as Color),
      title: Text(
        item['title'] as String,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: isDanger ? Colors.red.shade700 : Colors.black87,
        ),
      ),
      trailing: isDanger
          ? null
          : const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.grey,
            ),
      onTap: () {
        item['onTap'](context);
      },
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
      'color': _primaryColor,
      'onTap': (BuildContext context) => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => ProfileEditScreen())),
    });

    if (user.role != 'warga') {
      items.add({
        'title': 'Laporan Keuangan',
        'icon': Icons.account_balance_wallet_rounded,
        'color': _successColor,

        'onTap': (BuildContext context) => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ManajemenKeuanganScreen()),
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
