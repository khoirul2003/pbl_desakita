import 'package:frontend/models/iuran_model.dart';

class TagihanIuran {
  final int id;
  final int iuranId;
  final int? wargaId;
  final int? keluargaId;
  final int? periodeBulan;
  final int? periodeTahun;
  final double jumlahBayar;
  final String statusPembayaran;
  final DateTime? tanggalBayar;
  final String? paymentGatewayOrderId;

  final Iuran? iuran; // relasi ke master iuran (jika di-include di API)

  TagihanIuran({
    required this.id,
    required this.iuranId,
    this.wargaId,
    this.keluargaId,
    this.periodeBulan,
    this.periodeTahun,
    required this.jumlahBayar,
    required this.statusPembayaran,
    this.tanggalBayar,
    this.paymentGatewayOrderId,
    this.iuran,
  });

  factory TagihanIuran.fromJson(Map<String, dynamic> json) {
    DateTime? tanggalBayarParsed;
    if (json['tanggal_bayar'] != null) {
      try {
        tanggalBayarParsed = DateTime.parse(json['tanggal_bayar'].toString());
      } catch (_) {
        tanggalBayarParsed = null;
      }
    }

    Iuran? iuranData;
    if (json['iuran'] != null && json['iuran'] is Map<String, dynamic>) {
      iuranData = Iuran.fromJson(json['iuran'] as Map<String, dynamic>);
    }

    return TagihanIuran(
      id: int.tryParse(json['id'].toString()) ?? 0,
      iuranId: int.tryParse(json['iuran_id'].toString()) ?? 0,
      wargaId: json['warga_id'] != null
          ? int.tryParse(json['warga_id'].toString())
          : null,
      keluargaId: json['keluarga_id'] != null
          ? int.tryParse(json['keluarga_id'].toString())
          : null,
      periodeBulan: json['periode_bulan'] != null
          ? int.tryParse(json['periode_bulan'].toString())
          : null,
      periodeTahun: json['periode_tahun'] != null
          ? int.tryParse(json['periode_tahun'].toString())
          : null,
      jumlahBayar: double.tryParse(json['jumlah_bayar'].toString()) ?? 0.0,
      statusPembayaran: json['status_pembayaran']?.toString() ?? '',
      tanggalBayar: tanggalBayarParsed,
      paymentGatewayOrderId: json['payment_gateway_order_id']?.toString(),
      iuran: iuranData,
    );
  }

  Map<String, dynamic> toJsonMap() => {
    'id': id,
    'iuran_id': iuranId,
    'warga_id': wargaId,
    'keluarga_id': keluargaId,
    'periode_bulan': periodeBulan,
    'periode_tahun': periodeTahun,
    'jumlah_bayar': jumlahBayar,
    'status_pembayaran': statusPembayaran,
    'tanggal_bayar': tanggalBayar?.toIso8601String(),
    'payment_gateway_order_id': paymentGatewayOrderId,
    'iuran': iuran?.toJsonMap(),
  };

  bool get isLunas =>
      statusPembayaran.toLowerCase() == 'lunas' ||
      statusPembayaran.toLowerCase() == 'paid';
}
