import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';

import 'package:frontend/models/wallet_models.dart';
import 'package:frontend/services/api_service.dart';

// Konstanta untuk Gaya ProScan
const double _kCardRadius = 16.0; // Sudut membulat untuk Card/Container

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
  final Color primaryColor; // Navy Blue (untuk AppBar, Judul)
  final Color successColor; // Hijau/Warna Aksen (untuk data masuk)

  const DesaPayHistoryScreen({
    super.key,
    required this.primaryColor,
    required this.successColor,
  });

  /*
  =========================================================
  |       PROCESS DAN KOMPUTASI DATA FLOW (CHART)
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
  |       SUMMARY CARD: TOTAL MASUK & TOTAL KELUAR (Gaya ProScan)
  =========================================================
  */
  Widget buildSummaryCard(double inTotal, double outTotal) {
    final formatter = NumberFormat.currency(
      locale: "id_ID",
      symbol: "Rp ",
      decimalDigits: 0,
    );
    
    // Warna untuk Keluar (Merah)
    final Color expenseColor = Colors.red.shade700;
    // Warna untuk Masuk (Menggunakan successColor dari prop)
    final Color incomeColor = successColor; 

    return Container(
      padding: const EdgeInsets.all(20), // Padding lebih besar
      margin: const EdgeInsets.only(bottom: 20), // Margin lebih besar
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_kCardRadius), // Sudut membulat konsisten
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08), // Shadow lebih jelas
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Total Masuk
          Expanded(
            child: Column(
              children: [
                Icon(Icons.arrow_downward, color: incomeColor, size: 28),
                const SizedBox(height: 8),
                Text(
                  "Total Masuk",
                  style: TextStyle(
                    color: incomeColor,
                    fontWeight: FontWeight.w600, // Font lebih tebal
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatter.format(inTotal),
                  style: TextStyle(
                    fontSize: 18, // Font lebih besar
                    fontWeight: FontWeight.w800, // Sangat tebal
                    color: incomeColor,
                  ),
                ),
              ],
            ),
          ),
          
          // Divider
          Container(
            height: 60,
            width: 1,
            color: Colors.grey.shade300,
            margin: const EdgeInsets.symmetric(horizontal: 10),
          ),

          // Total Keluar
          Expanded(
            child: Column(
              children: [
                Icon(Icons.arrow_upward, color: expenseColor, size: 28),
                const SizedBox(height: 8),
                Text(
                  "Total Keluar",
                  style: TextStyle(
                    color: expenseColor,
                    fontWeight: FontWeight.w600, // Font lebih tebal
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatter.format(outTotal),
                  style: TextStyle(
                    fontSize: 18, // Font lebih besar
                    fontWeight: FontWeight.w800, // Sangat tebal
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

  /*
  =========================================================
  |                LINE CHART SALDO MASUK/KELUAR (Gaya ProScan)
  =========================================================
  */
  Widget buildFlowLineChart(
    List<String> dates,
    Map<String, double> inByDate,
    Map<String, double> outByDate,
  ) {
    if (dates.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_kCardRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Center(child: Text("Tidak ada data flow transaksi.")),
      );
    }

    List<FlSpot> inSpots = [];
    List<FlSpot> outSpots = [];

    for (int i = 0; i < dates.length; i++) {
      final d = dates[i];
      inSpots.add(FlSpot(i.toDouble(), inByDate[d] ?? 0));
      outSpots.add(FlSpot(i.toDouble(), outByDate[d] ?? 0));
    }

    final formatter = NumberFormat.compact(locale: "id_ID");

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8), // Padding bawah sedikit dikurangi
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_kCardRadius), // Sudut membulat konsisten
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Flow Transaksi Harian",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: primaryColor, // Judul menggunakan Primary Color
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 260,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false, // Hilangkan garis vertikal
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index < 0 || index >= dates.length) {
                          return const SizedBox();
                        }
                        final parts = dates[index].split("-");
                        // Tampilkan hanya tanggal
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            parts[2], 
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45, // Ruang lebih besar untuk label Y
                      getTitlesWidget: (value, meta) {
                        if (value <= 0) return const Text("0");
                        return Text(
                          formatter.format(value),
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    color: successColor, // Warna Masuk (Success/Aksen)
                    isCurved: true,
                    barWidth: 3.5, // Garis lebih tebal
                    dotData: const FlDotData(show: false),
                    spots: inSpots,
                  ),
                  LineChartBarData(
                    color: Colors.red.shade400, // Warna Keluar (Red)
                    isCurved: true,
                    barWidth: 3.5,
                    dotData: const FlDotData(show: false),
                    spots: outSpots,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Legenda Chart
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 10, height: 10, color: successColor),
              const SizedBox(width: 4),
              const Text("Masuk", style: TextStyle(fontSize: 12)),
              const SizedBox(width: 16),
              Container(width: 10, height: 10, color: Colors.red.shade400),
              const SizedBox(width: 4),
              const Text("Keluar", style: TextStyle(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  /*
  =========================================================
  |                      BUILD UI
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
      backgroundColor: Colors.grey.shade50, // Latar belakang sedikit abu-abu
      appBar: AppBar(
        title: const Text("Riwayat Transaksi Desapay"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: FutureBuilder<Response>(
        future: apiService.getBalanceAndTransactions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: primaryColor));
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
            padding: const EdgeInsets.all(20), // Padding lebih besar
            children: [
              // Summary Card (Gaya ProScan)
              buildSummaryCard(totalIn, totalOut),

              // Line Chart (Gaya ProScan)
              buildFlowLineChart(dates, inByDate, outByDate),

              const SizedBox(height: 16),
              Text(
                "Riwayat Transaksi Terbaru", // Judul lebih informatif
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: primaryColor), // Warna Primary
              ),
              const SizedBox(height: 12),

              // Daftar Transaksi
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

                // --- LIST TILE TRANSAKSI (Gaya ProScan) ---
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(_kCardRadius),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03), // Shadow lembut
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    // Hapus tileColor karena sudah di container
                    
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isIn
                            ? successColor.withOpacity(0.1) // successColor accent
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10), // Ikon membulat
                      ),
                      child: Icon(
                        isIn ? Icons.south_east : Icons.north_east, // Ikon arah modern
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
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    trailing: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "${isIn ? '+' : '-'}${formatter.format(totalAmount)}",
                          style: TextStyle(
                            color: isIn ? successColor : Colors.red.shade700,
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
      ),
    );
  }
}