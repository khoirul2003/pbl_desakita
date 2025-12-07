import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DesaPayIuranScreen extends StatefulWidget {
  final Color primaryColor;
  final Color accentColor;
  final Color successColor;

  const DesaPayIuranScreen({
    super.key,
    required this.primaryColor,
    required this.accentColor,
    required this.successColor,
  });

  @override
  State<DesaPayIuranScreen> createState() => _DesaPayIuranScreenState();
}

class _DesaPayIuranScreenState extends State<DesaPayIuranScreen> {
  late List<Map<String, dynamic>> _iuranList;

  @override
  void initState() {
    super.initState();
    _iuranList = [
      {
        'title': 'Iuran Keamanan Januari 2025',
        'description': 'Iuran keamanan lingkungan RT/RW',
        'amount': 25000,
        'dueDate': DateTime(2025, 1, 10),
        'paid': false,
      },
      {
        'title': 'Iuran Kebersihan Januari 2025',
        'description': 'Kebersihan lingkungan dan sampah',
        'amount': 20000,
        'dueDate': DateTime(2025, 1, 10),
        'paid': false,
      },
      {
        'title': 'Iuran Kas RT Desember 2024',
        'description': 'Kas RT bulanan',
        'amount': 15000,
        'dueDate': DateTime(2024, 12, 10),
        'paid': true,
      },
    ];
  }

  void _payIuran(int index) {
    final item = _iuranList[index];
    if (item['paid'] == true) {
      return;
    }

    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Bayar Iuran (Demo)"),
        content: Text(
          "Bayar ${item['title']} sebesar ${formatter.format(item['amount'])} "
          "menggunakan saldo Desapay?\n\n"
          "Ini hanya simulasi, belum tersambung ke server.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _iuranList[index]['paid'] = true;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Pembayaran ${item['title']} berhasil (demo)."),
                ),
              );
            },
            child: const Text("Bayar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateFormatter = DateFormat('dd MMM yyyy', 'id_ID');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pembayaran Iuran"),
        backgroundColor: widget.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _iuranList.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Text(
                "Daftar iuran lingkungan yang dapat dibayar menggunakan Desapay.\n"
                "Semua data masih dummy, nanti diganti dari API server.",
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
              ),
            );
          }

          final item = _iuranList[index - 1];
          final bool paid = item['paid'] as bool;
          final DateTime dueDate = item['dueDate'] as DateTime;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: paid
                          ? widget.successColor.withOpacity(0.15)
                          : widget.primaryColor.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      paid ? Icons.check_circle : Icons.receipt_long,
                      color: paid ? widget.successColor : widget.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title'] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['description'] as String,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Jatuh tempo: ${dateFormatter.format(dueDate)}",
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currencyFormatter.format(item['amount']),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: widget.accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (!paid)
                    ElevatedButton(
                      onPressed: () => _payIuran(index - 1),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Bayar",
                        style: TextStyle(fontSize: 12),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: widget.successColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        "Lunas",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: widget.successColor,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
