import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:frontend/models/user_model.dart';
import 'package:frontend/models/wallet_models.dart';
import 'package:frontend/services/api_service.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lottie/lottie.dart';

class DesaPayHistoryScreen extends StatelessWidget {
  final Color primaryColor;
  final Color successColor;

  const DesaPayHistoryScreen({
    super.key,
    required this.primaryColor,
    required this.successColor,
  });

  Map<String, dynamic> computeFlowData(List<Transaction> trx) {
    double totalIn = 0;
    double totalOut = 0;

    final Map<String, double> dailyIn = {};
    final Map<String, double> dailyOut = {};

    for (final t in trx) {
      final String date =
          "${t.createdAt.year}-${t.createdAt.month.toString().padLeft(2, '0')}-${t.createdAt.day.toString().padLeft(2, '0')}";

      final isIncoming = t.type == 'TOPUP' || t.type == 'TRANSFER_IN';

      if (isIncoming) {
        totalIn += t.amount;
        dailyIn[date] = (dailyIn[date] ?? 0) + t.amount;
      } else {
        final double total = t.amount + t.fee;
        totalOut += total;
        dailyOut[date] = (dailyOut[date] ?? 0) + total;
      }
    }

    final sortedKeys = {...dailyIn.keys, ...dailyOut.keys}.toList()..sort();

    return {
      'totalIn': totalIn,
      'totalOut': totalOut,
      'dates': sortedKeys,
      'inByDate': dailyIn,
      'outByDate': dailyOut,
    };
  }

  // Widget untuk menampilkan ringkasan transaksi
  Widget buildSummaryCard(double inTotal, double outTotal) {
    final formatter = NumberFormat.currency(
      locale: "id_ID",
      symbol: "Rp ",
      decimalDigits: 0,
    );

    final Color expenseColor = Colors.red.shade700;
    final Color incomeColor = successColor;

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: Column(
              children: [
                Icon(Icons.arrow_downward, color: incomeColor, size: 28),
                const SizedBox(height: 8),
                Text(
                  "Total Masuk",
                  style: TextStyle(
                    color: incomeColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatter.format(inTotal),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: incomeColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 60,
            width: 1,
            color: Colors.grey.shade300,
            margin: const EdgeInsets.symmetric(horizontal: 10),
          ),
          Expanded(
            child: Column(
              children: [
                Icon(Icons.arrow_upward, color: expenseColor, size: 28),
                const SizedBox(height: 8),
                Text(
                  "Total Keluar",
                  style: TextStyle(
                    color: expenseColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatter.format(outTotal),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: expenseColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ApiService apiService = ApiService();
    final formatter = NumberFormat.currency(
      locale: "id_ID",
      symbol: "Rp ",
      decimalDigits: 0,
    );
    final dateFormatter = DateFormat("dd MMM yyyy, HH:mm", "id_ID");

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Riwayat Transaksi Desapay"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: FutureBuilder<User?>(
        future: apiService.getUserDataFromStorage(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: SpinKitFadingCircle(color: Colors.blue, size: 50.0),
            );
          }

          if (userSnapshot.hasError || userSnapshot.data == null) {
            return const Center(child: Text("Gagal memuat data pengguna."));
          }

          final user = userSnapshot.data!;
          final userId = user.id;

          return FutureBuilder<Response>(
            future: apiService.getBalanceAndTransactions(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: SpinKitFadingCircle(color: Colors.blue, size: 50.0),
                );
              }

              if (snapshot.hasError || snapshot.data == null) {
                return const Center(child: Text("Gagal memuat data Desapay."));
              }

              final data = snapshot.data!.data;
              final summary = WalletSummary.fromJson(data);
              final txs = summary.transactions;

              // Filter transaksi berdasarkan pengirim atau penerima
              final filteredTxs = txs.where((tx) {
                return tx.sender?.id == userId || tx.receiver?.id == userId;
              }).toList();

              final flow = computeFlowData(filteredTxs);
              final totalIn = flow['totalIn'];
              final totalOut = flow['totalOut'];

              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  buildSummaryCard(totalIn, totalOut),

                  // Menampilkan chart transaksi
                  const SizedBox(height: 16),
                  Text(
                    "Riwayat Transaksi Terbaru",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Menampilkan riwayat transaksi
                  ...filteredTxs.map((tx) {
                    final bool isIn =
                        tx.type == "TOPUP" || tx.type == "TRANSFER_IN";
                    final double totalAmount = isIn
                        ? tx.amount
                        : (tx.amount + tx.fee);
                    final dateStr = dateFormatter.format(tx.createdAt);

                    String title;
                    switch (tx.type) {
                      case 'TOPUP':
                        title = "Top Up Saldo";
                        break;
                      case 'TRANSFER_OUT':
                        title =
                            "Transfer ke ${tx.receiver?.namaLengkap ?? 'Akun Lain'}";
                        break;
                      case 'TRANSFER_IN':
                        title =
                            "Terima Transfer dari ${tx.sender?.namaLengkap ?? 'Akun Lain'}";
                        break;
                      case 'PAYMENT_PPOB':
                        title = tx.description ?? "Pembayaran PPOB";
                        break;
                      default:
                        title = tx.description ?? tx.type;
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isIn
                                ? successColor.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isIn ? Icons.south_east : Icons.north_east,
                            color: isIn ? successColor : Colors.red.shade700,
                            size: 24,
                          ),
                        ),
                        title: Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        trailing: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "${isIn ? '+' : '-'}${formatter.format(totalAmount)}",
                              style: TextStyle(
                                color: isIn
                                    ? successColor
                                    : Colors.red.shade700,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                            if (!isIn && tx.fee > 0)
                              Text(
                                "Fee: ${formatter.format(tx.fee)}",
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
