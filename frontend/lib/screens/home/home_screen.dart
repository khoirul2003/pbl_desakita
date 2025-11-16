import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart'; // Import package chart

// Sesuaikan path ini
import 'package:frontend/models/user_model.dart'; // Perlu User Model
import 'package:frontend/state/auth_provider.dart';
import 'package:frontend/screens/login/login_screen.dart';
import 'package:frontend/screens/wajah/register_face_screen.dart';
import 'package:frontend/screens/placeholder_screen.dart';
// --- (BARU) Import layar manajemen warga ---
import 'package:frontend/screens/admin/manajemen_warga_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // List ini akan diisi berdasarkan role user
  List<Widget> _pages = [];
  List<BottomNavigationBarItem> _navItems = [];

  @override
  void initState() {
    super.initState();
    // Kita perlu AuthProvider untuk setup navigasi berdasarkan role
    // Kita tidak bisa 'watch' di initState, jadi kita 'read'
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _setupNavigation(authProvider.user);
  }

  void _setupNavigation(User? user) {
    if (user == null) return;

    // Halaman "Home" (Dashboard) selalu ada di index 0
    List<Widget> pages = [_HomeTabContent(user: user)];
    List<BottomNavigationBarItem> navItems = [
      const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
    ];

    // Tentukan sisa menu berdasarkan role
    if (user.role == 'admin') {
      pages.addAll([
        // --- (PERUBAHAN) Ganti PlaceholderScreen ---
        const ManajemenWargaScreen(), // <-- DARI: const PlaceholderScreen(title: "Manajemen Warga"),
        const PlaceholderScreen(title: "Manajemen Iuran"),
        const PlaceholderScreen(title: "Manajemen Keuangan"),
      ]);
      navItems.addAll([
        const BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Warga'),
        const BottomNavigationBarItem(icon: Icon(Icons.paid), label: 'Iuran'),
        const BottomNavigationBarItem(
          icon: Icon(Icons.account_balance_wallet),
          label: 'Keuangan',
        ),
      ]);
    } else if (user.role == 'rt' || user.role == 'rw') {
      pages.addAll([
        const PlaceholderScreen(title: "Data Warga"),
        const PlaceholderScreen(title: "Kelola Iuran"),
        const PlaceholderScreen(title: "Laporan Keuangan"),
      ]);
      navItems.addAll([
        const BottomNavigationBarItem(
          icon: Icon(Icons.people_outline),
          label: 'Warga',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.paid_outlined),
          label: 'Iuran',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.assessment_outlined),
          label: 'Keuangan',
        ),
      ]);
    } else {
      // Role 'warga'
      pages.addAll([
        const PlaceholderScreen(title: "Tagihan Iuran"),
        const PlaceholderScreen(title: "Kegiatan Desa"),
        const PlaceholderScreen(title: "Profil Saya"),
      ]);
      navItems.addAll([
        const BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long),
          label: 'Tagihan',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.event_available),
          label: 'Kegiatan',
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

    // Jika (karena alasan aneh) user null, kembali ke login
    if (!authProvider.isAuthenticated || user == null) {
      return const LoginScreen();
    }

    return Scaffold(
      appBar: AppBar(
        // Judul AppBar berubah sesuai tab yang dipilih
        title: const Text("Desakita"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
            onPressed: () async {
              await authProvider.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      // IndexedStack menjaga state setiap halaman saat berpindah tab
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        items: _navItems,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        // Ini penting agar label selalu terlihat
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

// --- (BARU) Widget Terpisah untuk Konten Tab "Home" ---
// Ini berisi konten yang sebelumnya ada di body ListView

class _HomeTabContent extends StatelessWidget {
  final User user;
  const _HomeTabContent({required this.user});

  @override
  Widget build(BuildContext context) {
    final warga = user.warga;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // --- (BAGIAN HEADER SELAMAT DATANG) ---
        Text(
          "Selamat Datang,",
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Text(
          user.warga?.namaLengkap ?? user.email,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (warga != null)
          Text(
            "Warga RT ${warga.rt} / RW ${warga.rw}",
            style: Theme.of(context).textTheme.titleMedium,
          ),
        const SizedBox(height: 20),
        // Tombol untuk atur login wajah
        OutlinedButton.icon(
          icon: const Icon(Icons.face_retouching_natural),
          label: const Text("Atur Login Wajah"),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RegisterFaceScreen()),
            );
          },
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Divider(),

        // --- (PERUBAHAN) Tampilkan Dashboard Berdasarkan Role ---
        _buildDashboardByRole(context, user),
      ],
    );
  }

  // (BARU) Helper untuk memilih dashboard yang sesuai
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
    return const SizedBox.shrink(); // Kosong jika tidak ada role
  }

  /// (BARU) Widget untuk menampilkan Kartu Statistik RT/RW
  Widget _buildRtRwDashboard(BuildContext context, User user) {
    // TODO: Ganti data palsu ini dengan data dari API
    // Buat endpoint baru di Laravel: GET /api/v1/dashboard-stats
    final String totalWarga = "45";
    final String totalKK = "15";
    final String iuranBelumLunas = "3";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          "Ringkasan Data ${user.role.toUpperCase()} ${user.warga?.rt ?? ''}/${user.warga?.rw ?? ''}",
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2, // Membuat kartu sedikit lebih tinggi
          children: [
            _StatCard(
              icon: Icons.people,
              title: "Total Warga",
              value: totalWarga,
              color: Colors.blue,
            ),
            _StatCard(
              icon: Icons.house,
              title: "Total KK",
              value: totalKK,
              color: Colors.orange,
            ),
            _StatCard(
              icon: Icons.receipt,
              title: "Iuran Belum Lunas",
              value: iuranBelumLunas,
              color: Colors.red,
            ),
            _StatCard(
              icon: Icons.event,
              title: "Kegiatan Aktif",
              value: "1", // Dummy
              color: Colors.purple,
            ),
          ],
        ),
      ],
    );
  }

  /// (BARU) Widget untuk menampilkan Kartu Statistik Warga
  Widget _buildWargaDashboard(BuildContext context, User user) {
    // TODO: Ganti data palsu ini dengan data dari API
    final String tagihanWarga = "2";
    final String totalTagihan = "Rp 150.000";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          "Ringkasan Akun Saya",
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            _StatCard(
              icon: Icons.receipt_long,
              title: "Tagihan Belum Lunas",
              value: tagihanWarga,
              color: Colors.red,
            ),
            _StatCard(
              icon: Icons.account_balance_wallet,
              title: "Total Tagihan",
              value: totalTagihan,
              color: Colors.green,
            ),
          ],
        ),
      ],
    );
  }

  /// (TIDAK BERUBAH) Widget untuk menampilkan chart dashboard admin
  Widget _buildAdminDashboard(BuildContext context) {
    // ... (kode chart admin yang sudah ada) ...
    // TODO: Ganti data palsu ini dengan data dari API
    final dummyFinancialData = [
      {'label': 'Jan', 'pemasukan': 1500000.0, 'pengeluaran': 800000.0},
      {'label': 'Feb', 'pemasukan': 1200000.0, 'pengeluaran': 1100000.0},
      {'label': 'Mar', 'pemasukan': 2000000.0, 'pengeluaran': 1000000.0},
    ];

    final dummyResidentData = [
      {'role': 'Admin', 'count': 2, 'color': Colors.red},
      {'role': 'RW', 'count': 5, 'color': Colors.orange},
      {'role': 'RT', 'count': 20, 'color': Colors.blue},
      {'role': 'Warga', 'count': 250, 'color': Colors.green},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text("Ringkasan Data", style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        // Chart Keuangan
        SizedBox(
          height: 200,
          child: Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _FinancialBarChart(data: dummyFinancialData),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Chart Komposisi Warga
        SizedBox(
          height: 200,
          child: Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _ResidentPieChart(data: dummyResidentData),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Divider(),
      ],
    );
  }
}

// --- (BARU) Widget Kartu Statistik ---
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    this.color = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 36, color: color),
            const Spacer(),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(title, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

// --- (Widget Chart: Tidak Berubah) ---
class _FinancialBarChart extends StatelessWidget {
  // ... (kode chart yang sudah ada) ...
  final List<Map<String, dynamic>> data;
  const _FinancialBarChart({required this.data});

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
                color: Colors.green,
                width: 16,
              ),
              BarChartRodData(
                toY: item['pengeluaran'],
                color: Colors.red,
                width: 16,
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
              reservedSize: 20,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (double value, TitleMeta meta) {
                // Sederhanakan label (misal: 1000000 -> 1Jt)
                if (value % 500000 == 0 && value != 0) {
                  return Text(
                    "${(value / 1000000).toStringAsFixed(1)}Jt",
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const Text("");
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
      ),
    );
  }
}

class _ResidentPieChart extends StatelessWidget {
  // ... (kode chart yang sudah ada) ...
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
                  radius: 50,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
              sectionsSpace: 2,
              centerSpaceRadius: 40,
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: data.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Container(width: 16, height: 16, color: item['color']),
                    const SizedBox(width: 8),
                    Text(item['role']),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
