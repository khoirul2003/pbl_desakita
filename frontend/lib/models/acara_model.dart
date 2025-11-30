import 'dart:convert';

class Acara {
  final int id;
  final String namaAcara;
  final String deskripsi;
  final DateTime tanggalMulai;
  final DateTime tanggalSelesai;
  final String lokasi;
  final String? rt;
  final String? rw;
  final int? createdByUserId;

  Acara({
    required this.id,
    required this.namaAcara,
    required this.deskripsi,
    required this.tanggalMulai,
    required this.tanggalSelesai,
    required this.lokasi,
    this.rt,
    this.rw,
    this.createdByUserId,
  });

  factory Acara.fromJson(Map<String, dynamic> json) {
    return Acara(
      id: json['id'],
      namaAcara: json['nama_acara'], // Perhatikan nama field dari Laravel
      deskripsi: json['deskripsi'],
      // Parsing String ISO 8601 menjadi DateTime
      tanggalMulai: DateTime.parse(json['tanggal_mulai']),
      tanggalSelesai: DateTime.parse(json['tanggal_selesai']),
      lokasi: json['lokasi'],
      rt: json['rt'],
      rw: json['rw'],
      createdByUserId: json['created_by_user_id'] != null
          ? int.tryParse(json['created_by_user_id'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJsonMap() => {
    'id': id,
    'nama_acara': namaAcara,
    'deskripsi': deskripsi,
    // Konversi kembali ke format String untuk pengiriman API
    'tanggal_mulai': tanggalMulai.toIso8601String(),
    'tanggal_selesai': tanggalSelesai.toIso8601String(),
    'lokasi': lokasi,
    'rt': rt,
    'rw': rw,
    'created_by_user_id': createdByUserId,
  };
}
