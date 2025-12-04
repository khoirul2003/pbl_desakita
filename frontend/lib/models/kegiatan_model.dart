import 'dart:convert';

class Kegiatan {
  final int id;
  final String namaKegiatan;
  final String deskripsi;
  final DateTime tanggalMulai;
  final DateTime tanggalSelesai;
  final String lokasi;
  final String? rt;
  final String? rw;
  final double totalBiaya; // Biaya untuk pendanaan
  final int? createdByUserId;

  Kegiatan({
    required this.id,
    required this.namaKegiatan,
    required this.deskripsi,
    required this.tanggalMulai,
    required this.tanggalSelesai,
    required this.lokasi,
    this.rt,
    this.rw,
    required this.totalBiaya,
    this.createdByUserId,
  });

  factory Kegiatan.fromJson(Map<String, dynamic> json) {
    return Kegiatan(
      id: json['id'],
      namaKegiatan: json['nama_kegiatan'],
      deskripsi: json['deskripsi'],
      // Parsing String ISO 8601 menjadi DateTime
      tanggalMulai: DateTime.parse(json['tanggal_mulai']),
      tanggalSelesai: DateTime.parse(json['tanggal_selesai']),
      lokasi: json['lokasi'],
      rt: json['rt'],
      rw: json['rw'],
      // PENTING: Konversi total_biaya dari String (Decimal) ke Double
      totalBiaya: double.tryParse(json['total_biaya'].toString()) ?? 0.0,
      createdByUserId: json['created_by_user_id'] != null
          ? int.tryParse(json['created_by_user_id'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJsonMap() => {
    'id': id,
    'nama_kegiatan': namaKegiatan,
    'deskripsi': deskripsi,
    'tanggal_mulai': tanggalMulai.toIso8601String(),
    'tanggal_selesai': tanggalSelesai.toIso8601String(),
    'lokasi': lokasi,
    'rt': rt,
    'rw': rw,
    'total_biaya': totalBiaya,
    'created_by_user_id': createdByUserId,
  };
}
