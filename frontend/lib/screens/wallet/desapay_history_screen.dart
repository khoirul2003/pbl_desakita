import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';

import 'package:frontend/services/api_service.dart';
import 'package:frontend/models/wallet_models.dart';

class DesaPayHistoryScreen extends StatelessWidget {
  final Color primaryColor;
  final Color successColor;

  const DesaPayHistoryScreen({
    super.key,
    required this.primaryColor,
    required this.successColor,
  });

  @override
  Widget build(BuildContext context) {
    final ApiService apiService = ApiService();
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateFormatter = DateFormat("dd MMM yyyy, HH:mm", "id_ID");

    return Scaffold(
      appBar: AppBar(
        title: const Text("Riwayat Transaksi Desapay"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<WalletSummary?>(
        future: apiService.getWalletSummary(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            String msg = "Gagal memuat riwayat transaksi.";
            final error = snapshot.error;
            if (error is DioException) {
              final data = error.response?.data;
              if (data is Map && data['message'] != null) {
                msg = data['message'].toString();
              }
            }
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  msg,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          final summary = snapshot.data;
          final txs = summary?.transactions ?? [];

          if (txs.isEmpty) {
            return const Center(
              child: Text(
                "Belum ada transaksi Desapay.",
                style: TextStyle(fontSize: 13),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16.0),
            itemCount: txs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final tx = txs[index];
              final bool isIn = tx.type == 'TOPUP' || tx.type == 'TRANSFER_IN';
              final DateTime date = tx.createdAt;
              final String dateStr = dateFormatter.format(date);

              String title;
              switch (tx.type) {
                case 'TOPUP':
                  title = "Top Up Saldo";
                  break;
                case 'TRANSFER_OUT':
                  title =
                      "Transfer ke ${tx.receiver?.namaLengkap ?? 'Akun lain'}";
                  break;
                case 'TRANSFER_IN':
                  title =
                      "Terima transfer dari ${tx.sender?.namaLengkap ?? 'Akun lain'}";
                  break;
                case 'PAYMENT_PPOB':
                  title = tx.description ?? "Pembayaran PPOB";
                  break;
                default:
                  title = tx.description ?? tx.type;
              }

              final double totalAmount = isIn
                  ? tx.amount
                  : (tx.amount + tx.fee);

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isIn
                      ? successColor.withOpacity(0.2)
                      : Colors.red.withOpacity(0.15),
                  child: Icon(
                    isIn ? Icons.arrow_downward : Icons.arrow_upward,
                    color: isIn ? successColor : Colors.red,
                  ),
                ),
                title: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(dateStr, style: const TextStyle(fontSize: 12)),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${isIn ? '+' : '-'}${formatter.format(totalAmount)}",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: isIn ? successColor : Colors.red,
                        fontSize: 13,
                      ),
                    ),
                    if (!isIn && tx.fee > 0)
                      Text(
                        "Fee: ${formatter.format(tx.fee)}",
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
