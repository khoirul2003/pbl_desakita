import 'dart:convert';

class Iuran {
  final int id;
  final String namaIuran;
  final String? deskripsi;
  final double jumlah;
  final String tipe; // 'PER_WARGA' atau 'PER_KELUARGA'
  final String? rt; // null jika level RW/Desa
  final String? rw; // null jika level Desa

  Iuran({
    required this.id,
    required this.namaIuran,
    this.deskripsi,
    required this.jumlah,
    required this.tipe,
    this.rt,
    this.rw,
  });

  factory Iuran.fromJson(Map<String, dynamic> json) {
    return Iuran(
      id: json['id'],
      namaIuran: json['nama_iuran'],
      deskripsi: json['deskripsi'],
      jumlah: double.tryParse(json['jumlah'].toString()) ?? 0.0,
      tipe: json['tipe'],
      rt: json['rt'],
      rw: json['rw'],
    );
  }

  get jatuhTempo => null;

  Map<String, dynamic> toJsonMap() => {
    'id': id,
    'nama_iuran': namaIuran,
    'deskripsi': deskripsi,
    'jumlah': jumlah,
    'tipe': tipe,
    'rt': rt,
    'rw': rw,
  };
}
