import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/models/user_model.dart';
import 'package:frontend/models/wallet_models.dart';
import 'package:frontend/screens/placeholder_screen.dart';
import 'package:frontend/screens/wallet/topup_screen.dart';
import 'package:frontend/screens/wallet/pembelian_pulsa_screen.dart'; 
// *** BARU: Import Pembelian Paket Data Screen ***
import 'package:frontend/screens/wallet/pembelian_paket_data_screen.dart'; 
import 'package:frontend/state/auth_provider.dart';

// --- DEFINISI WARNA PROSCAN ---
const Color _primaryColor = Color(0xFF0E2F60); // Biru Tua
const Color _accentColor = Color(0xFF3C486B); // Aksen Biru/Abu
const Color _successColor = Color(0xFF28A745); // Hijau untuk Kredit/Pemasukan
const Color _dangerColor = Colors.red; // Merah untuk Debit/Pengeluaran

class PPOBMenuItem {
  final String title;
  final IconData icon;
  final Color color;
  final Function(BuildContext) onTap;

  PPOBMenuItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class HomeTabWalletContent extends StatefulWidget {
  final User user;
  const HomeTabWalletContent({super.key, required this.user});

  @override
  State<HomeTabWalletContent> createState() => _HomeTabWalletContentState();
}

class _HomeTabWalletContentState extends State<HomeTabWalletContent> {
  List<Transaction> _transactions = [];
  bool _isLoading = true;
  String _errorMessage = '';

  final NumberFormat _rupiahFormatter = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  // Helper function untuk Card Wrapper dengan Shadow ProScan
  Widget _buildCardWrapper({required Widget child, EdgeInsets padding = const EdgeInsets.all(16)}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16, // Shadow menonjol dan lembut
            offset: const Offset(0, 6),
          )
        ],
      ),
      padding: padding,
      child: child,
    );
  }


  @override
  void initState() {
    super.initState();
    _fetchWalletDataViaProvider();
  }

  Future<void> _fetchWalletDataViaProvider() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final authProvider = context.read<AuthProvider>();
    final apiService = context.read<ApiService>();

    try {
      final data = await apiService.getWalletData();
      if (data != null && mounted) {
        await authProvider.tryAutoLogin();

        setState(() {
          _transactions = data['transactions'] as List<Transaction>;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Gagal memuat Desapay: ${e.toString()}";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onTopUp(BuildContext context) async {
    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const TopUpScreen()));
    if (result == true) {
      _fetchWalletDataViaProvider();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final Wallet? currentWallet = authProvider.user?.warga?.wallet;
    final List<Transaction> currentTransactions = _transactions;

    if (_isLoading && currentWallet == null) {
      return const Center(child: CircularProgressIndicator(color: _primaryColor));
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text("Error Desapay: $_errorMessage"),
        ),
      );
    }

    if (currentWallet == null) {
      return const Center(child: Text("Dompet Desapay belum terdaftar."));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Kartu Saldo (Wallet Info)
        _WalletInfoCard(
          wallet: currentWallet,
          rupiahFormatter: _rupiahFormatter,
          onTopUp: () => _onTopUp(context),
          onRefresh: _fetchWalletDataViaProvider,
          primaryColor: _primaryColor,
          accentColor: _accentColor,
        ),

        const SizedBox(height: 30),

        // 2. Menu PPOB (Pulsa, Iuran, dll.)
        _PPOBMenuGrid(
          user: widget.user,
          fetchWalletData:
              _fetchWalletDataViaProvider,
          primaryColor: _primaryColor,
          buildCardWrapper: _buildCardWrapper,
        ),

        const SizedBox(height: 30),

        // 3. Riwayat Transaksi (Dibawah menu PPOB)
        Text(
          "Riwayat Transaksi Terakhir",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: _primaryColor,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 8),
        currentTransactions.isEmpty
            ? const Text("Belum ada transaksi.")
            : Column(
                children: currentTransactions
                    .map((t) => _buildTransactionTile(t))
                    .toList(),
              ),
      ],
    );
  }

  // Widget untuk menampilkan 1 baris riwayat transaksi (Disesuaikan ProScan)
  Widget _buildTransactionTile(Transaction t) {
    final bool isDebit =
        t.type.contains('OUT') ||
        t.type == 'PAYMENT_IURAN' ||
        t.type == 'PAYMENT_PPOB';
    final Color amountColor = isDebit ? _dangerColor : _successColor;
    final String sign = isDebit ? '-' : '+';

    String title;
    if (t.type == 'TOPUP') {
      title = "Isi Saldo (Demo)";
    } else if (t.type == 'TRANSFER_OUT') {
      title = "Transfer ke ${t.receiver?.namaLengkap ?? 'Akun Lain'}";
    } else if (t.type == 'TRANSFER_IN') {
      title = "Terima dari ${t.sender?.namaLengkap ?? 'Akun Lain'}";
    } else {
      title = t.description ?? t.type;
    }

    final String formattedDate = DateFormat(
      'dd MMM, HH:mm',
    ).format(t.createdAt.toLocal());

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: _buildCardWrapper( // Bungkus dalam card wrapper untuk efek shadow
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: amountColor.withOpacity(0.1),
              child: Icon(
                isDebit ? Icons.arrow_upward : Icons.arrow_downward,
                color: amountColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(formattedDate, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "$sign ${_rupiahFormatter.format(t.amount)}",
                  style: TextStyle(color: amountColor, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                if (t.fee > 0)
                  Text(
                    "Biaya: ${_rupiahFormatter.format(t.fee)}",
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// --- WIDGET 1: Kartu Info Saldo (Disesuaikan ProScan) ---

class _WalletInfoCard extends StatelessWidget {
  final Wallet wallet;
  final NumberFormat rupiahFormatter;
  final VoidCallback onTopUp;
  final Future<void> Function() onRefresh;
  final Color primaryColor;
  final Color accentColor;

  const _WalletInfoCard({
    required this.wallet,
    required this.rupiahFormatter,
    required this.onTopUp,
    required this.onRefresh,
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          // Gradient Biru Tua ke Biru Aksen
          gradient: LinearGradient(
            colors: [
              primaryColor,
              accentColor,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Saldo Desapay Anda",
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  rupiahFormatter.format(wallet.balance),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 26,
                      ),
                ),
                // Tombol Refresh Saldo
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: onRefresh,
                  tooltip: "Refresh Saldo",
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tombol Cepat: Isi Saldo, Transfer, Bayar QR
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _WalletActionButton(
                  icon: Icons.add_circle_outline,
                  label: "Isi Saldo",
                  onPressed: onTopUp,
                ),
                _WalletActionButton(
                  icon: Icons.send_time_extension,
                  label: "Transfer",
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            const PlaceholderScreen(title: "Transfer Desapay"),
                      ),
                    );
                  },
                ),
                _WalletActionButton(
                  icon: Icons.qr_code_scanner,
                  label: "Bayar (QR)",
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            const PlaceholderScreen(title: "Pembayaran QR"),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Widget untuk tombol cepat di kartu saldo (Disesuaikan ProScan)
class _WalletActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _WalletActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white24, // Background putih transparan
              borderRadius: BorderRadius.circular(12),
            ),
            // Menggunakan ikon yang sesuai dari properti
            child: Icon(icon, color: Colors.white, size: 28), 
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// --- WIDGET 2: Menu PPOB (Grid) ---

class _PPOBMenuGrid extends StatelessWidget {
  final User user;
  final Future<void> Function() fetchWalletData; 
  final Color primaryColor;
  final Widget Function({required Widget child, EdgeInsets padding}) buildCardWrapper; // Menerima Card Wrapper

  const _PPOBMenuGrid({
    required this.user,
    required this.fetchWalletData,
    required this.primaryColor,
    required this.buildCardWrapper,
  });

  @override
  Widget build(BuildContext context) {
    final List<PPOBMenuItem> menuItems = [
      PPOBMenuItem(
        title: "Pulsa",
        icon: Icons.phone_android,
        color: Colors.red,
        onTap: (ctx) async {
          final result = await Navigator.of(ctx).push(
            MaterialPageRoute(builder: (_) => const PembelianPulsaScreen()),
          );
          if (result == true) {
            fetchWalletData();
          }
        },
      ),
      PPOBMenuItem(
        title: "Paket Data",
        icon: Icons.wifi,
        color: Colors.blue,
        // *** PERBAIKAN DI SINI ***
        onTap: (ctx) async {
          final result = await Navigator.of(ctx).push(
            MaterialPageRoute(builder: (_) => const PembelianPaketDataScreen()),
          );
          if (result == true) {
            fetchWalletData();
          }
        },
      ),
      PPOBMenuItem(
        title: "Token Listrik",
        icon: Icons.flash_on,
        color: Colors.orange,
        onTap: (ctx) => Navigator.of(ctx).push(
          MaterialPageRoute(
            builder: (_) =>
                const PlaceholderScreen(title: "Pembelian Token Listrik"),
          ),
        ),
      ),
      PPOBMenuItem(
        title: "Bayar BPJS",
        icon: Icons.health_and_safety,
        color: Colors.indigo,
        onTap: (ctx) => Navigator.of(ctx).push(
          MaterialPageRoute(
            builder: (_) => const PlaceholderScreen(title: "Pembayaran BPJS"),
          ),
        ),
      ),
      PPOBMenuItem(
        title: "Bayar Iuran",
        icon: Icons.receipt_long,
        color: _successColor, // Hijau
        onTap: (ctx) => Navigator.of(ctx).push(
          MaterialPageRoute(
            builder: (_) =>
                const PlaceholderScreen(title: "Pembayaran Iuran Desa"),
          ),
        ),
      ),
      PPOBMenuItem(
        title: "Lainnya",
        icon: Icons.apps,
        color: Colors.grey,
        onTap: (ctx) => Navigator.of(ctx).push(
          MaterialPageRoute(
            builder: (_) => const PlaceholderScreen(title: "Menu PPOB Lainnya"),
          ),
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Layanan Pembayaran",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: primaryColor,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: menuItems.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1.0, 
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (context, index) {
            final item = menuItems[index];
            return buildCardWrapper( // Menggunakan Card Wrapper ProScan
              padding: const EdgeInsets.all(8),
              child: InkWell(
                onTap: () => item.onTap(context),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item.icon, size: 36, color: item.color),
                    const SizedBox(height: 8),
                    Text(
                      item.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}