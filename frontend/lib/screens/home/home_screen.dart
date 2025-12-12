import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import 'package:frontend/models/user_model.dart';
import 'package:frontend/state/auth_provider.dart';
import 'package:frontend/screens/placeholder_screen.dart';
import 'package:frontend/screens/admin/manajemen_warga_screen.dart';
import 'package:frontend/screens/admin/manajemen_iuran_screen.dart';
import 'package:frontend/screens/admin/manajemen_kegiatan_screen.dart';
import 'package:frontend/screens/profile/profile_main_screen.dart';
import 'package:frontend/screens/wallet/desapay_wallet_section.dart';
import 'package:frontend/screens/rt_rw/manajemen_warga_rt_rw_screen.dart'; 
import 'package:frontend/screens/rt_rw/manajemen_iuran_rt_rw_screen.dart'; 

const Color _primaryColor = Color(0xFF0E2F60);
const Color _accentColor = Color(0xFF3C486B);
const Color _backgroundColor = Color(0xFFF5F5F5);
const Color _successColor = Color(0xFF28A745);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  List<Widget> _pages = [];
  List<BottomNavigationBarItem> _navItems = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      _setupNavigation(authProvider.user);
    });
  }

  void _setupNavigation(User? user) {
    if (user == null) return;

    List<Widget> pages = [_HomeTabContent(user: user)];
    List<BottomNavigationBarItem> navItems = [
      const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
    ];

    if (user.role == 'admin' || user.role == 'rt' || user.role == 'rw') {

      // 1. Tentukan halaman Manajemen Warga
      Widget manajemenWargaPage;
      if (user.role == 'admin') {
        manajemenWargaPage = const ManajemenWargaScreen(); // Admin melihat SEMUA Warga
      } else { 
        // Role 'rt' dan 'rw' akan diarahkan ke screen yang sudah difilter
        manajemenWargaPage = const ManajemenWargaRtRwScreen();
      }

      // 2. Tentukan halaman Manajemen Iuran
      Widget manajemenIuranPage;
      if (user.role == 'admin') {
        manajemenIuranPage = const ManajemenIuranScreen(); // Admin melihat SEMUA Iuran
      } else {
        // Role 'rt' dan 'rw' akan diarahkan ke screen Iuran yang difilter
        manajemenIuranPage = const ManajemenIuranRtRwScreen(); 
      }

      // 3. Tambahkan semua halaman ke list pages
      pages.addAll([
        manajemenWargaPage,
        manajemenIuranPage,
        const ManajemenKegiatanScreen(), // Kegiatan bisa dilihat semua
        const ProfileMainScreen(),
      ]);

      navItems.addAll([
        const BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Warga'),
        const BottomNavigationBarItem(icon: Icon(Icons.paid), label: 'Iuran'),
        const BottomNavigationBarItem(
          icon: Icon(Icons.event),
          label: 'Kegiatan',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Profil',
        ),
      ]);
    } else {
      // Logika untuk Warga Biasa
      pages.addAll([
        const PlaceholderScreen(title: "Data Keluarga Saya"),
        const PlaceholderScreen(title: "Tagihan Iuran"),
        const ProfileMainScreen(),
      ]);

      navItems.addAll([
        const BottomNavigationBarItem(
          icon: Icon(Icons.family_restroom),
          label: 'Keluarga',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long),
          label: 'Iuran',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Profil',
        ),
      ]);
    }

    setState(() {
      _pages = pages;
      _navItems = navItems;
      _selectedIndex = 0;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    if (!authProvider.isAuthenticated || user == null || _pages.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text("DesaKita"),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          items: _navItems,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: _primaryColor,
          unselectedItemColor: Colors.grey[500],
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
    );
  }
}

class _HomeTabContent extends StatelessWidget {
  final User user;
  const _HomeTabContent({required this.user});

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
  Widget build(BuildContext context) {
    final warga = user.warga;
    final String greeting = _getGreeting();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
      children: [
        Text(
          greeting,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        Text(
          user.warga?.namaLengkap ?? user.email,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: _primaryColor,
              ),
        ),
        if (warga != null)
          Text(
            "Warga RT ${warga.rt} / RW ${warga.rw}",
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.grey[500]),
          ),
        const SizedBox(height: 20),

        // === Card saldo Desapay + menu layanan lain ===
        _buildCardWrapper(
          child: const DesaPayWalletSection(
            primaryColor: _primaryColor,
            accentColor: _accentColor,
            successColor: _successColor,
          ),
        ),
        const SizedBox(height: 20),

        // =================================================
        _buildDashboardByRole(context, user),
        const SizedBox(height: 40),
      ],
    );
  }

  String _getGreeting() {
    final now = DateTime.now().hour;
    if (now >= 5 && now < 11) {
      return "Selamat Pagi! ";
    } else if (now >= 11 && now < 15) {
      return "Selamat Siang! ";
    } else if (now >= 15 && now < 18) {
      return "Selamat Sore! ";
    } else {
      return "Selamat Malam! ";
    }
  }

  Widget _buildDashboardByRole(BuildContext context, User user) {
    if (user.role == 'admin') {
      return _buildAdminDashboard(context);
    }
    if (user.role == 'rt' || user.role == 'rw') {
      return _buildRtRwDashboard(context, user);
    }
    if (user.role == 'warga') {
      return _buildWargaDashboard(context, user);
    }
    return const SizedBox.shrink();
  }

  Widget _buildRtRwDashboard(BuildContext context, User user) {
    final String totalWarga = "45";
    final String totalKK = "15";
    final String iuranBelumLunas = "3";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Ringkasan Data ${user.role.toUpperCase()} ${user.warga?.rt ?? ''}/${user.warga?.rw ?? ''}",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: _accentColor,
              ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.9,
          children: [
            _StatCard(
              icon: Icons.people_alt_rounded,
              title: "Total Warga",
              value: totalWarga,
              color: _primaryColor,
              cardWrapper: _buildCardWrapper,
            ),
            _StatCard(
              icon: Icons.house_rounded,
              title: "Total KK",
              value: totalKK,
              color: Colors.orange,
              cardWrapper: _buildCardWrapper,
            ),
            _StatCard(
              icon: Icons.receipt,
              title: "Iuran Belum Lunas",
              value: iuranBelumLunas,
              color: Colors.red,
              cardWrapper: _buildCardWrapper,
            ),
            _StatCard(
              icon: Icons.event_available,
              title: "Kegiatan Aktif",
              value: "1",
              color: Colors.purple,
              cardWrapper: _buildCardWrapper,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWargaDashboard(BuildContext context, User user) {
    final String tagihanWarga = "2";
    final String totalTagihan = "Rp 150.000";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Ringkasan Tagihan Anda",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: _accentColor,
              ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.9,
          children: [
            _StatCard(
              icon: Icons.receipt_long,
              title: "Tagihan Belum Lunas",
              value: tagihanWarga,
              color: Colors.red,
              cardWrapper: _buildCardWrapper,
            ),
            _StatCard(
              icon: Icons.account_balance_wallet_rounded,
              title: "Total Tagihan",
              value: totalTagihan,
              color: _successColor,
              cardWrapper: _buildCardWrapper,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdminDashboard(BuildContext context) {
    final dummyFinancialData = [
      {'label': 'Jan', 'pemasukan': 1500000.0, 'pengeluaran': 800000.0},
      {'label': 'Feb', 'pemasukan': 1200000.0, 'pengeluaran': 1100000.0},
      {'label': 'Mar', 'pemasukan': 2000000.0, 'pengeluaran': 1000000.0},
    ];

    final dummyResidentData = [
      {'role': 'Admin', 'count': 2, 'color': Colors.red},
      {'role': 'RW', 'count': 5, 'color': Colors.orange},
      {'role': 'RT', 'count': 20, 'color': _primaryColor},
      {'role': 'Warga', 'count': 250, 'color': _successColor},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Ringkasan Data (Admin)",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: _accentColor,
              ),
        ),
        const SizedBox(height: 16),

        _buildCardWrapper(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            height: 200,
            child: _FinancialBarChart(
              data: dummyFinancialData,
              primaryColor: _primaryColor,
              successColor: _successColor,
            ),
          ),
        ),
        const SizedBox(height: 16),

        _buildCardWrapper(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            height: 200,
            child: _ResidentPieChart(data: dummyResidentData),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final Widget Function({required Widget child, EdgeInsets padding})
      cardWrapper;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.cardWrapper,
  });

  @override
  Widget build(BuildContext context) {
    return cardWrapper(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 16),
          // MODIFIKASI: Mengubah headlineMedium menjadi titleLarge
          // atau menentukan fontSize eksplisit untuk mengatasi overflow
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                  // Jika titleLarge masih terlalu besar, coba turunkan fontSize secara eksplisit:
                  // fontSize: 24, 
                ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class _FinancialBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final Color primaryColor;
  final Color successColor;

  const _FinancialBarChart({
    required this.data,
    required this.primaryColor,
    required this.successColor,
  });

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barGroups: data.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: item['pemasukan'],
                color: successColor,
                width: 12,
                borderRadius: BorderRadius.circular(4),
              ),
              BarChartRodData(
                toY: item['pengeluaran'],
                color: primaryColor,
                width: 12,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }).toList(),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            axisNameWidget: const Text(
              "Pemasukan & Pengeluaran Bulanan",
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
            axisNameSize: 20,
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    data[value.toInt()]['label'],
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (double value, TitleMeta meta) {
                if (value % 500000 == 0 && value != 0) {
                  final formatter = NumberFormat.compact(locale: 'id');
                  return Text(
                    formatter.format(value),
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const Text("");
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 500000,
        ),
      ),
    );
  }
}

class _ResidentPieChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const _ResidentPieChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final total = data.fold(0.0, (sum, item) => sum + item['count']);

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: PieChart(
            PieChartData(
              sections: data.map((item) {
                final percentage = (item['count'] / total) * 100;
                return PieChartSectionData(
                  color: item['color'],
                  value: percentage,
                  title: '${percentage.toStringAsFixed(0)}%',
                  radius: 60,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
              sectionsSpace: 3,
              centerSpaceRadius: 40,
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Distribusi Pengguna:",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: _primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              ...data.map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: item['color'],
                          borderRadius: BorderRadius.circular(3),
                        ),
                        margin: const EdgeInsets.only(right: 8),
                      ),
                      Text(
                        "${item['role']} (${item['count']})",
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }
}