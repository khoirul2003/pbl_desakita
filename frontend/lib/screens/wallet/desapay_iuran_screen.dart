import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';

import 'package:frontend/services/api_service.dart';
import 'package:frontend/models/tagihan_iuran_model.dart';

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
  final ApiService _apiService = ApiService();

  bool _loading = true;
  String? _errorMessage;
  List<TagihanIuran> _tagihanList = [];

  /// Status lunas lokal setelah bayar (supaya UI langsung update)
  final Set<int> _paidLocal = {};

  @override
  void initState() {
    super.initState();
    _loadTagihan();
  }

  Future<void> _loadTagihan() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final list = await _apiService.getTagihanIuranWarga();
      setState(() {
        _tagihanList = list;
        _loading = false;
      });
    } on DioException catch (e) {
      String msg = "Gagal memuat tagihan iuran.";
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        msg = data['message'].toString();
      }
      setState(() {
        _errorMessage = msg;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _errorMessage = "Terjadi kesalahan saat memuat tagihan iuran.";
        _loading = false;
      });
    }
  }

  String _formatPeriode(int? bulan, int? tahun) {
    if (bulan == null || tahun == null) return "-";
    const bulanNames = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    if (bulan < 1 || bulan > 12) return "$bulan/$tahun";
    return "${bulanNames[bulan]} $tahun";
  }

  Future<void> _payTagihan(TagihanIuran tagihan) async {
    final alreadyPaid = tagihan.isLunas || _paidLocal.contains(tagihan.id);
    if (alreadyPaid) return;

    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final double amount = tagihan.jumlahBayar > 0
        ? tagihan.jumlahBayar
        : (tagihan.iuran?.jumlah ?? 0.0);

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Nominal tagihan tidak valid. Periksa data iuran di server.",
          ),
        ),
      );
      return;
    }

    const double fee = 1000.0;
    final total = amount + fee;

    final namaIuran = tagihan.iuran?.namaIuran ?? 'Iuran';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Konfirmasi Pembayaran"),
        content: Text(
          "Bayar tagihan \"$namaIuran\"\n"
          "Periode: ${_formatPeriode(tagihan.periodeBulan, tagihan.periodeTahun)}\n"
          "Nominal: ${currencyFormatter.format(amount)}\n"
          "Biaya admin: ${currencyFormatter.format(fee)}\n\n"
          "Total dipotong dari saldo Desapay: ${currencyFormatter.format(total)}",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Bayar"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _loading = true;
    });

    try {
      // 1. Potong saldo dan catat transaksi di wallet (PAYMENT_PPOB)
      final newBalance = await _apiService.payPPOB(
        amount: amount,
        productName:
            'Iuran: $namaIuran (${_formatPeriode(tagihan.periodeBulan, tagihan.periodeTahun)})',
        targetNumber: 'TAGIHAN_${tagihan.id}',
        fee: fee,
      );

      // 2. Tandai tagihan sebagai dibayar di modul fitur
      await _apiService.bayarTagihanIuran(tagihan.id);

      setState(() {
        _paidLocal.add(tagihan.id);
        _loading = false;
      });

      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Pembayaran Berhasil"),
          content: Text(
            "Pembayaran tagihan \"$namaIuran\" berhasil.\n"
            "Nominal: ${currencyFormatter.format(amount)}\n"
            "Biaya admin: ${currencyFormatter.format(fee)}\n\n"
            "Saldo baru: ${newBalance != null ? currencyFormatter.format(newBalance) : '-'}",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // dialog
                Navigator.of(
                  context,
                ).pop(true); // kembali ke home, refresh saldo
              },
              child: const Text("Tutup"),
            ),
          ],
        ),
      );
    } on DioException catch (e) {
      String msg = "Pembayaran tagihan gagal.";
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        msg = data['message'].toString();
      }
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (_) {
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pembayaran tagihan gagal.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Tagihan Iuran"),
        backgroundColor: widget.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _loadTagihan,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text("Muat ulang"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          : _tagihanList.isEmpty
          ? const Center(
              child: Text(
                "Tidak ada tagihan iuran untuk akun ini.",
                style: TextStyle(fontSize: 13),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _tagihanList.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                  );
                }

                final tagihan = _tagihanList[index - 1];
                final iuran = tagihan.iuran;
                final namaIuran = iuran?.namaIuran ?? 'Iuran';
                final tipe = iuran?.tipe ?? '-';
                final wilayah = [
                  if (iuran?.rt != null && (iuran!.rt ?? '').isNotEmpty)
                    "RT ${iuran.rt}",
                  if (iuran?.rw != null && (iuran!.rw ?? '').isNotEmpty)
                    "RW ${iuran.rw}",
                ].join(' / ');

                final bool isPaid =
                    tagihan.isLunas || _paidLocal.contains(tagihan.id);

                final double amount = tagihan.jumlahBayar > 0
                    ? tagihan.jumlahBayar
                    : (iuran?.jumlah ?? 0.0);

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
                            color: isPaid
                                ? widget.successColor.withOpacity(0.15)
                                : widget.primaryColor.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isPaid ? Icons.check_circle : Icons.receipt_long,
                            color: isPaid
                                ? widget.successColor
                                : widget.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                namaIuran,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Periode: ${_formatPeriode(tagihan.periodeBulan, tagihan.periodeTahun)}",
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blueGrey.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      tipe.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  if (wilayah.isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    Text(
                                      wilayah,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currencyFormatter.format(amount),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: widget.accentColor,
                                ),
                              ),
                              if (tagihan.isLunas &&
                                  tagihan.tanggalBayar != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  "Dibayar: ${DateFormat('dd MMM yyyy', 'id_ID').format(tagihan.tanggalBayar!)}",
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (!isPaid)
                          ElevatedButton(
                            onPressed: _loading
                                ? null
                                : () => _payTagihan(tagihan),
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
