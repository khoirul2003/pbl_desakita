import 'dart:convert';

import 'package:intl/intl.dart';

class Keuangan {
  final int id;
  final String tipe;
  final double jumlah;
  final String keterangan;
  final DateTime tanggal;
  final String? rt;
  final String? rw;
  final int? createdByUserId;

  Keuangan({
    required this.id,
    required this.tipe,
    required this.jumlah,
    required this.keterangan,
    required this.tanggal,
    this.rt,
    this.rw,
    this.createdByUserId,
  });

  factory Keuangan.fromJson(Map<String, dynamic> json) {
    return Keuangan(
      id: json['id'],
      tipe: json['tipe'],
      jumlah: double.tryParse(json['jumlah'].toString()) ?? 0.0,
      keterangan: json['keterangan'],
      tanggal: DateTime.parse(
        json['tanggal'],
      ), // Parsing tanggal dari format YYYY-MM-DD
      rt: json['rt'],
      rw: json['rw'],
      createdByUserId: json['created_by_user_id'] != null
          ? int.tryParse(json['created_by_user_id'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJsonMap() => {
    'id': id,
    'tipe': tipe,
    'jumlah': jumlah,
    'keterangan': keterangan,
    // Konversi kembali ke format String YYYY-MM-DD untuk API
    'tanggal': DateFormat('yyyy-MM-dd').format(tanggal),
    'rt': rt,
    'rw': rw,
    'created_by_user_id': createdByUserId,
  };
}
