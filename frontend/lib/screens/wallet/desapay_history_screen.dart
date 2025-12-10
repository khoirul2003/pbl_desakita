import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';

import 'package:frontend/models/wallet_models.dart';
import 'package:frontend/services/api_service.dart';

class WalletSummary {
  final Wallet wallet;
  final List<Transaction> transactions;

  WalletSummary({required this.wallet, required this.transactions});

  factory WalletSummary.fromJson(Map<String, dynamic> json) {
    return WalletSummary(
      wallet: Wallet.fromJson(json['wallet']),
      transactions: (json['transactions'] as List)
          .map((e) => Transaction.fromJson(e))
          .toList(),
    );
  }
}

class DesaPayHistoryScreen extends StatelessWidget {
  final Color primaryColor;
  final Color successColor;

  const DesaPayHistoryScreen({
    super.key,
    required this.primaryColor,
    required this.successColor,
  });

  /*
  =========================================================
  |       PROCESS DAN KOMPUTASI DATA FLOW (CHART)
  =========================================================
  */
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

  /*
  =========================================================
  |       SUMMARY CARD: TOTAL MASUK & TOTAL KELUAR
  =========================================================
  */
  Widget buildSummaryCard(double inTotal, double outTotal) {
    final formatter = NumberFormat.currency(
      locale: "id_ID",
      symbol: "Rp ",
      decimalDigits: 0,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text(
                "Total Masuk",
                style: TextStyle(
                  color: Colors.green[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formatter.format(inTotal),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          Column(
            children: [
              Text(
                "Total Keluar",
                style: TextStyle(
                  color: Colors.red[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formatter.format(outTotal),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /*
  =========================================================
  |                LINE CHART SALDO MASUK/KELUAR
  =========================================================
  */
  Widget buildFlowLineChart(
    List<String> dates,
    Map<String, double> inByDate,
    Map<String, double> outByDate,
  ) {
    if (dates.isEmpty) return const SizedBox();

    List<FlSpot> inSpots = [];
    List<FlSpot> outSpots = [];

    for (int i = 0; i < dates.length; i++) {
      final d = dates[i];
      inSpots.add(FlSpot(i.toDouble(), inByDate[d] ?? 0));
      outSpots.add(FlSpot(i.toDouble(), outByDate[d] ?? 0));
    }

    final formatter = NumberFormat.compact(locale: "id_ID");

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SizedBox(
        height: 260,
        child: LineChart(
          LineChartData(
            gridData: const FlGridData(show: true),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    int index = value.toInt();
                    if (index < 0 || index >= dates.length) {
                      return const SizedBox();
                    }
                    final parts = dates[index].split("-");
                    return Text(
                      "${parts[2]}/${parts[1]}",
                      style: const TextStyle(fontSize: 10),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    if (value <= 0) return const Text("0");
                    return Text(
                      formatter.format(value),
                      style: const TextStyle(fontSize: 10),
                    );
                  },
                ),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                color: Colors.green,
                isCurved: true,
                barWidth: 3,
                spots: inSpots,
              ),
              LineChartBarData(
                color: Colors.red,
                isCurved: true,
                barWidth: 3,
                spots: outSpots,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /*
  =========================================================
  |                      BUILD UI
  =========================================================
  */
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
      appBar: AppBar(
        title: const Text("Riwayat Transaksi Desapay"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Response>(
        future: apiService.getBalanceAndTransactions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || snapshot.data == null) {
            return const Center(child: Text("Gagal memuat data Desapay."));
          }

          final data = snapshot.data!.data;
          final summary = WalletSummary.fromJson(data);
          final txs = summary.transactions;

          final flow = computeFlowData(txs);
          final totalIn = flow['totalIn'];
          final totalOut = flow['totalOut'];

          final dates = flow['dates'];
          final inByDate = flow['inByDate'];
          final outByDate = flow['outByDate'];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Summary Card
              buildSummaryCard(totalIn, totalOut),

              // Line Chart
              buildFlowLineChart(dates, inByDate, outByDate),

              const SizedBox(height: 12),
              const Text(
                "Riwayat Transaksi",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              ...txs.map((tx) {
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
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    tileColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    leading: CircleAvatar(
                      backgroundColor: isIn
                          ? Colors.green.withOpacity(0.2)
                          : Colors.red.withOpacity(0.2),
                      child: Icon(
                        isIn ? Icons.arrow_downward : Icons.arrow_upward,
                        color: isIn ? Colors.green : Colors.red,
                      ),
                    ),
                    title: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      dateStr,
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "${isIn ? '+' : '-'}${formatter.format(totalAmount)}",
                          style: TextStyle(
                            color: isIn ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
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
                  ),
                );
              }).toList(),
            ],
          );
        },
      ),
    );
  }
}
