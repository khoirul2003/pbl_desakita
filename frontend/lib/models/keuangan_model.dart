import 'dart:convert';
import 'package:frontend/models/user_model.dart'; // Jika model Keuangan memuat relasi user

class Keuangan {
  final int id;
  final String tipe; // PEMASUKAN atau PENGELUARAN
  final double jumlah;
  final String keterangan;
  final DateTime tanggal;
  final String? rt; // Kas RT
  final String? rw; // Kas RW
  final int? createdByUserId;
  // Jika API memuat data pembuat
  final User? pencatat;

  Keuangan({
    required this.id,
    required this.tipe,
    required this.jumlah,
    required this.keterangan,
    required this.tanggal,
    this.rt,
    this.rw,
    this.createdByUserId,
    this.pencatat,
  });

  factory Keuangan.fromJson(Map<String, dynamic> json) {
    return Keuangan(
      id: json['id'],
      tipe: json['tipe'],
      // Parsing jumlah dari String/num (dari DB) ke double
      jumlah: double.tryParse(json['jumlah'].toString()) ?? 0.0,
      keterangan: json['keterangan'],
      // Pastikan parsing tanggal dari format YYYY-MM-DD
      tanggal: DateTime.parse(json['tanggal']), 
      rt: json['rt'],
      rw: json['rw'],
      createdByUserId: json['created_by_user_id'] != null 
          ? int.tryParse(json['created_by_user_id'].toString()) 
          : null,
      pencatat: json['pencatat'] != null ? User.fromJson(json['pencatat']) : null,
    );
  }

  Map<String, dynamic> toJsonMap() => {
    'id': id,
    'tipe': tipe,
    'jumlah': jumlah,
    'keterangan': keterangan,
    'tanggal': tanggal.toIso8601String(),
    'rt': rt,
    'rw': rw,
    'created_by_user_id': createdByUserId,
    'pencatat': pencatat?.toJsonMap(),
  };
}