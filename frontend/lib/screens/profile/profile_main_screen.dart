import 'package:flutter/material.dart';
import 'package:frontend/screens/profile/profile_edit_screen.dart';
import 'package:provider/provider.dart';
import 'package:frontend/state/auth_provider.dart';
import 'package:frontend/models/user_model.dart';
import 'package:frontend/screens/placeholder_screen.dart';
import 'package:intl/intl.dart';
import 'package:frontend/screens/wajah/register_face_screen.dart'; 
// --- Import Layar Manajemen & Profil ---
import 'package:frontend/screens/admin/manajemen_keuangan_screen.dart'; 
import 'package:frontend/screens/admin/manajemen_acara_screen.dart'; 
import 'package:frontend/screens/profile/detail_profile_screen.dart'; 
// *** FIX: Import ChangePasswordScreen yang baru ***
import 'package:frontend/screens/profile/change_password_screen.dart'; 
// (Asumsi: File manajemen lain tetap diimport di proyek utama, tapi dihilangkan di sini karena sudah dihapus dari menu)

const Color _primaryColor = Color(0xFF0E2F60);
const Color _accentColor = Color(0xFF3C486B);
const Color _backgroundColor = Color(0xFFF5F5F5);
const Color _successColor = Color(0xFF28A745);

class ProfileMainScreen extends StatefulWidget { 
  const ProfileMainScreen({super.key});

  @override
  State<ProfileMainScreen> createState() => _ProfileMainScreenState();
}

class _ProfileMainScreenState extends State<ProfileMainScreen> {
  
  Future<void> _goToProfileDetail(BuildContext context, User user) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DetailProfileScreen()), 
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
  
  Widget _buildCustomHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8, left: 16, right: 16, bottom: 16,
      ),
      decoration: const BoxDecoration(
        color: _primaryColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Profil & Pengaturan", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, User user) {
    final String? balance = user.warga?.wallet?.balance.toStringAsFixed(0);
    final String formattedBalance = balance != null
        ? "Rp ${NumberFormat.currency(locale: 'id', symbol: '', decimalDigits: 0).format(double.parse(balance))}"
        : "Rp 0";
    
    return _buildCardWrapper(
      child: InkWell(
        onTap: () => _goToProfileDetail(context, user), 
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0), 
          child: Row(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: _primaryColor.withOpacity(0.1),
                child: Text(user.warga?.namaLengkap.isNotEmpty == true ? user.warga!.namaLengkap[0].toUpperCase() : user.email[0].toUpperCase(),
                  style: const TextStyle(fontSize: 30, color: _primaryColor, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.warga?.namaLengkap ?? "Pengguna Desa", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: _primaryColor), overflow: TextOverflow.ellipsis),
                    Text("Role: ${user.role.toUpperCase()}", style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.w500)),
                    if (user.warga != null) Text("RT ${user.warga!.rt} / RW ${user.warga!.rw}", style: TextStyle(color: Colors.grey[600])),
                    if (balance != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text("Saldo: $formattedBalance", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: _successColor)),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: _accentColor), 
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, Map<String, dynamic> item) {
    final bool isDanger = item['color'] == Colors.red;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Icon(item['icon'] as IconData, color: item['color'] as Color),
      title: Text(item['title'] as String, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: isDanger ? Colors.red.shade700 : Colors.black87)),
      trailing: isDanger ? null : const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
      onTap: () { item['onTap'](context); },
    );
  }

  List<Map<String, dynamic>> _buildMenuItems(User user, AuthProvider authProvider) {
    List<Map<String, dynamic>> items = [];

    // --- Menu Umum (Pengaturan Pribadi) ---
    items.add({
      'title': 'Atur Login Wajah',
      'icon': Icons.face_retouching_natural,
      'color': Colors.blueGrey,
      'onTap': (BuildContext context) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterFaceScreen())),
    });

    items.add({
      'title': 'Ganti Password/Profil',
      'icon': Icons.security,
      'color': _primaryColor,
      // *** FIX: Arahkan ke ChangePasswordScreen ***
      'onTap': (BuildContext context) => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
      ),
    });

    // --- Menu Manajemen (Hanya untuk Admin/RT/RW) ---
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
        'onTap': (BuildContext context) => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ManajemenAcaraScreen()),
        ),
      });
    }

    // --- Menu Khusus Warga ---
    if (user.role == 'warga') {
      items.add({
        'title': 'Data Keluarga Saya',
        'icon': Icons.family_restroom,
        'color': _accentColor,
        'onTap': (BuildContext context) => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PlaceholderScreen(title: "Data Keluarga Saya")),
        ),
      });
    }

    // --- Menu Logout di akhir list ---
    items.add({
      'title': 'Logout',
      'icon': Icons.logout,
      'color': Colors.red,
      'onTap': (BuildContext context) async {
        await authProvider.logout();
        if (context.mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      },
    });

    return items;
  }
  
  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    if (user == null) {
      return const Center(child: Text("Data pengguna tidak ditemukan."));
    }

    final List<Map<String, dynamic>> menuItems = _buildMenuItems(user, authProvider);
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 20.0,
              ),
              children: [
                _buildProfileCard(context, user), 
                const SizedBox(height: 30),

                Text("Akses Fitur Cepat", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: _primaryColor, fontSize: 18)),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
