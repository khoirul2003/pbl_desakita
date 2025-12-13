import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';

import 'package:frontend/models/wallet_models.dart';
import 'package:frontend/services/api_service.dart';

import 'package:frontend/screens/wallet/desapay_topup_screen.dart';
import 'package:frontend/screens/wallet/desapay_transfer_screen.dart';
import 'package:frontend/screens/wallet/desapay_history_screen.dart';
import 'package:frontend/screens/wallet/desapay_pulsa_screen.dart';
import 'package:frontend/screens/wallet/desapay_paket_data_screen.dart';
import 'package:frontend/screens/wallet/desapay_token_listrik_screen.dart';
import 'package:frontend/screens/wallet/desapay_iuran_screen.dart';

class DesaPayWalletSection extends StatefulWidget {
  final Color primaryColor;
  final Color accentColor;
  final Color successColor;

  const DesaPayWalletSection({
    super.key,
    required this.primaryColor,
    required this.accentColor,
    required this.successColor,
  });

  @override
  State<DesaPayWalletSection> createState() => _DesaPayWalletSectionState();
}

class _DesaPayWalletSectionState extends State<DesaPayWalletSection> {
  final ApiService _apiService = ApiService();

  Wallet? _wallet;
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final summary = await _apiService.getWalletSummary();
      setState(() {
        _wallet = summary?.wallet;
        _loading = false;
      });
    } on DioException catch (e) {
      String msg = 'Gagal memuat data Desapay.';
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        msg = data['message'].toString();
      }
      setState(() {
        _errorMessage = msg;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan saat memuat Desapay.';
        _loading = false;
      });
    }
  }

  Future<void> _navigateAndRefresh(Widget page) async {
    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => page));
    if (result == true) {
      await _loadWallet();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return SizedBox(
        height: 100,
        child: Center(
          child: CircularProgressIndicator(color: widget.primaryColor),
        ),
      );
    }

    if (_errorMessage != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Saldo Desapay",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: widget.accentColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: const TextStyle(fontSize: 12, color: Colors.red),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _loadWallet,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text("Coba lagi"),
          ),
        ],
      );
    }

    if (_wallet == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Saldo Desapay",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: widget.accentColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Wallet tidak ditemukan untuk akun ini.",
            style: TextStyle(fontSize: 12, color: Colors.red),
          ),
        ],
      );
    }

    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final balanceText = currencyFormatter.format(_wallet!.balance);
    final accountNumber =
        _wallet!.desapayAccountNumber ?? "Belum memiliki nomor Desapay";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "Saldo Desapay",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: widget.accentColor,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: _loadWallet,
              icon: const Icon(Icons.refresh, size: 18),
              tooltip: 'Refresh',
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    balanceText,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: widget.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text(
                        "No. Akun Desapay:",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          accountNumber,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: widget.accentColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: widget.primaryColor.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.account_balance_wallet_rounded,
                size: 32,
                color: widget.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Aksi utama: Top Up, Transfer, Riwayat
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            _DesaPayActionButton(
              icon: Icons.add_circle_outline,
              label: "Top Up",
              primaryColor: widget.primaryColor,
              onTap: () {
                _navigateAndRefresh(
                  DesaPayTopUpScreen(
                    primaryColor: widget.primaryColor,
                    accentColor: widget.accentColor,
                  ),
                );
              },
            ),
            _DesaPayActionButton(
              icon: Icons.swap_horiz_rounded,
              label: "Transfer",
              primaryColor: widget.primaryColor,
              onTap: () {
                _navigateAndRefresh(
                  DesaPayTransferScreen(
                    primaryColor: widget.primaryColor,
                    accentColor: widget.accentColor,
                  ),
                );
              },
            ),
            _DesaPayActionButton(
              icon: Icons.receipt_long,
              label: "Riwayat",
              primaryColor: widget.primaryColor,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DesaPayHistoryScreen(
                      primaryColor: widget.primaryColor,
                      successColor: widget.successColor,
                    ),
                  ),
                );
              },
            ),
          ],
        ),

        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 8),

        Text(
          "Layanan lain",
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: widget.accentColor,
          ),
        ),
        const SizedBox(height: 8),

        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 0.8,
          children: [
            _DesaPayServiceItem(
              icon: Icons.phone_android,
              label: "Pulsa",
              primaryColor: widget.primaryColor,
              onTap: () {
                _navigateAndRefresh(
                  DesaPayPulsaScreen(
                    primaryColor: widget.primaryColor,
                    accentColor: widget.accentColor,
                  ),
                );
              },
            ),
            _DesaPayServiceItem(
              icon: Icons.data_usage,
              label: "Paket Data",
              primaryColor: widget.primaryColor,
              onTap: () {
                _navigateAndRefresh(
                  DesaPayPaketDataScreen(
                    primaryColor: widget.primaryColor,
                    accentColor: widget.accentColor,
                  ),
                );
              },
            ),
            _DesaPayServiceItem(
              icon: Icons.bolt,
              label: "Token Listrik",
              primaryColor: widget.primaryColor,
              onTap: () {
                _navigateAndRefresh(
                  DesaPayTokenListrikScreen(
                    primaryColor: widget.primaryColor,
                    accentColor: widget.accentColor,
                    successColor: widget.successColor,
                  ),
                );
              },
            ),
            _DesaPayServiceItem(
              icon: Icons.apartment_rounded,
              label: "Iuran",
              primaryColor: widget.primaryColor,
              onTap: () {
                _navigateAndRefresh(
                  DesaPayIuranScreen(
                    primaryColor: widget.primaryColor,
                    accentColor: widget.accentColor,
                    successColor: widget.successColor,
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _DesaPayActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color primaryColor;
  final VoidCallback onTap;

  const _DesaPayActionButton({
    required this.icon,
    required this.label,
    required this.primaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: primaryColor.withOpacity(0.05),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: primaryColor),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DesaPayServiceItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color primaryColor;
  final VoidCallback onTap;

  const _DesaPayServiceItem({
    required this.icon,
    required this.label,
    required this.primaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: primaryColor),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }
}
