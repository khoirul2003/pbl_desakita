import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/models/user_model.dart';
import 'package:frontend/models/wallet_models.dart';
import 'package:frontend/screens/placeholder_screen.dart';
import 'package:frontend/screens/wallet/topup_screen.dart';
import 'package:frontend/screens/wallet/pembelian_pulsa_screen.dart'; // Import Pembelian Pulsa
import 'package:frontend/state/auth_provider.dart';

// Definisi Model untuk Item PPOB (Pulsa, BPJS, dll.)
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
  // Hanya menyimpan transaksi di state lokal untuk riwayat
  List<Transaction> _transactions = [];
  bool _isLoading = true;
  String _errorMessage = '';

  // Formatter untuk Rupiah
  final NumberFormat _rupiahFormatter = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp',
    decimalDigits: 0,
  );

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
        // PENTING: Panggil tryAutoLogin untuk memperbarui data user (termasuk wallet) di Provider
        await authProvider.tryAutoLogin();

        setState(() {
          // Hanya update transaksi di sini
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
    // Pindah ke layar TopUp
    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const TopUpScreen()));
    // Jika TopUp berhasil, refresh data
    if (result == true) {
      _fetchWalletDataViaProvider(); // Panggil fungsi refresh
    }
  }

  @override
  Widget build(BuildContext context) {
    // Kita watch AuthProvider untuk mendapatkan data saldo terbaru
    final authProvider = context.watch<AuthProvider>();
    final Wallet? currentWallet = authProvider.user?.warga?.wallet;
    final List<Transaction> currentTransactions = _transactions;

    if (_isLoading && currentWallet == null) {
      return const Center(child: CircularProgressIndicator());
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
          onRefresh: _fetchWalletDataViaProvider, // Panggil fungsi refresh
        ),

        const SizedBox(height: 24),

        // 2. Menu PPOB (Pulsa, Iuran, dll.)
        _PPOBMenuGrid(
          user: widget.user,
          fetchWalletData:
              _fetchWalletDataViaProvider, // Teruskan fungsi refresh
        ),

        const SizedBox(height: 24),

        // 3. Riwayat Transaksi (Dibawah menu PPOB)
        Text(
          "Riwayat Transaksi Terakhir",
          style: Theme.of(context).textTheme.titleLarge,
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

  // Widget untuk menampilkan 1 baris riwayat transaksi
  Widget _buildTransactionTile(Transaction t) {
    final bool isDebit =
        t.type.contains('OUT') ||
        t.type == 'PAYMENT_IURAN' ||
        t.type == 'PAYMENT_PPOB';
    final Color amountColor = isDebit ? Colors.red : Colors.green;
    final String sign = isDebit ? '-' : '+';

    // Tentukan deskripsi berdasarkan tipe
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

    // Format tanggal
    final String formattedDate = DateFormat(
      'dd MMM, HH:mm',
    ).format(t.createdAt.toLocal());

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: amountColor.withOpacity(0.1),
        child: Icon(
          isDebit ? Icons.arrow_upward : Icons.arrow_downward,
          color: amountColor,
        ),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(formattedDate),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "$sign ${_rupiahFormatter.format(t.amount)}",
            style: TextStyle(color: amountColor, fontWeight: FontWeight.bold),
          ),
          if (t.fee > 0)
            Text(
              "Biaya: ${_rupiahFormatter.format(t.fee)}",
              style: const TextStyle(color: Colors.grey, fontSize: 10),
            ),
        ],
      ),
    );
  }
}

// --- WIDGET 1: Kartu Info Saldo ---

class _WalletInfoCard extends StatelessWidget {
  final Wallet wallet;
  final NumberFormat rupiahFormatter;
  final VoidCallback onTopUp;
  final Future<void> Function() onRefresh;

  const _WalletInfoCard({
    required this.wallet,
    required this.rupiahFormatter,
    required this.onTopUp,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      // Gunakan gradient agar terlihat mewah
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
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
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Tombol Refresh Saldo
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: onRefresh,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tombol Cepat: Top Up, Transfer, Tarik Tunai
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

// Widget untuk tombol cepat di kartu saldo
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
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.menu, color: Colors.white, size: 24),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}

// --- WIDGET 2: Menu PPOB (Grid) ---

class _PPOBMenuGrid extends StatelessWidget {
  final User user;
  final Future<void> Function() fetchWalletData; // <-- Terima refresh function

  const _PPOBMenuGrid({required this.user, required this.fetchWalletData});

  @override
  Widget build(BuildContext context) {
    final List<PPOBMenuItem> menuItems = [
      PPOBMenuItem(
        title: "Pulsa",
        icon: Icons.phone_android,
        color: Colors.red,
        // NAVIGASI PULSA DENGAN RESULT
        onTap: (ctx) async {
          final result = await Navigator.of(ctx).push(
            MaterialPageRoute(builder: (_) => const PembelianPulsaScreen()),
          );
          // PENTING: Jika ada perubahan (TopUp/Bayar) di layar pulsa, refresh data
          if (result == true) {
            fetchWalletData();
          }
        },
      ),
      PPOBMenuItem(
        title: "Paket Data",
        icon: Icons.wifi,
        color: Colors.blue,
        onTap: (ctx) => Navigator.of(ctx).push(
          MaterialPageRoute(
            builder: (_) =>
                const PlaceholderScreen(title: "Pembelian Paket Data"),
          ),
        ),
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
        color: Colors.green,
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
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: menuItems.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio:
                1.0, // Perbandingan yang baik untuk 3 item per baris
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (context, index) {
            final item = menuItems[index];
            return InkWell(
              onTap: () => item.onTap(context),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item.icon, size: 36, color: item.color),
                    const SizedBox(height: 8),
                    Text(
                      item.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13),
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
