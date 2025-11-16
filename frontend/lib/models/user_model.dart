import 'dart:convert';





class User {
  final int id;
  final String email;
  final String role;
  final Warga? warga; 

  User({required this.id, required this.email, required this.role, this.warga});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      role: json['role'],
      
      warga: json['warga'] != null ? Warga.fromJson(json['warga']) : null,
    );
  }

  
  String toJsonString() => json.encode(_toJson());
  Map<String, dynamic> _toJson() => {
    'id': id,
    'email': email,
    'role': role,
    'warga': warga?._toJson(),
  };

  factory User.fromJsonString(String str) => User.fromJson(json.decode(str));
}



class Warga {
  final int id;
  final String nik;
  final String namaLengkap;
  final String rt;
  final String rw;
  final String? tempatLahir;
  final String?
  tanggalLahir; 
  final String? jenisKelamin;
  final String? alamatKtp;
  final String? agama;
  final String? statusPerkawinan;
  final String? pekerjaan;
  final String? kewarganegaraan;
  final int? keluargaId;
  final String? statusDalamKeluarga;
  final String? noHp;
  final String? fotoKtp; 

  
  final Keluarga? keluarga;
  final User? user; 

  Warga({
    required this.id,
    required this.nik,
    required this.namaLengkap,
    required this.rt,
    required this.rw,
    this.tempatLahir,
    this.tanggalLahir,
    this.jenisKelamin,
    this.alamatKtp,
    this.agama,
    this.statusPerkawinan,
    this.pekerjaan,
    this.kewarganegaraan,
    this.keluargaId,
    this.statusDalamKeluarga,
    this.noHp,
    this.fotoKtp,

    
    this.keluarga,
    this.user,
  });

  factory Warga.fromJson(Map<String, dynamic> json) {
    return Warga(
      id: json['id'],
      nik: json['nik'],
      namaLengkap: json['nama_lengkap'],
      rt: json['rt'],
      rw: json['rw'],
      tempatLahir: json['tempat_lahir'],
      tanggalLahir: json['tanggal_lahir'],
      jenisKelamin: json['jenis_kelamin'],
      alamatKtp: json['alamat_ktp'],
      agama: json['agama'],
      statusPerkawinan: json['status_perkawinan'],
      pekerjaan: json['pekerjaan'],
      kewarganegaraan: json['kewarganegaraan'],
      keluargaId: json['keluarga_id'] != null
          ? int.tryParse(json['keluarga_id'].toString())
          : null,
      statusDalamKeluarga: json['status_dalam_keluarga'],
      noHp: json['no_hp'],
      fotoKtp: json['foto_ktp'],

      
      keluarga: json['keluarga'] != null
          ? Keluarga.fromJson(json['keluarga'])
          : null,
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }

  Map<String, dynamic> _toJson() => {
    'id': id,
    'nik': nik,
    'nama_lengkap': namaLengkap,
    'rt': rt,
    'rw': rw,
    'tempat_lahir': tempatLahir,
    'tanggal_lahir': tanggalLahir,
    'jenis_kelamin': jenisKelamin,
    'alamat_ktp': alamatKtp,
    'agama': agama,
    'status_perkawinan': statusPerkawinan,
    'pekerjaan': pekerjaan,
    'kewarganegaraan': kewarganegaraan,
    'keluarga_id': keluargaId,
    'status_dalam_keluarga': statusDalamKeluarga,
    'no_hp': noHp,
    'foto_ktp': fotoKtp,
    
    'keluarga': keluarga?._toJson(),
    'user': user?._toJson(),
  };
}




class Keluarga {
  final int id;
  final String noKk;
  final String alamat;
  final String rt;
  final String rw;
  final int? kepalaKeluargaId;
  
  

  Keluarga({
    required this.id,
    required this.noKk,
    required this.alamat,
    required this.rt,
    required this.rw,
    this.kepalaKeluargaId,
    
  });

  factory Keluarga.fromJson(Map<String, dynamic> json) {
    
    
    
    
    
    
    

    return Keluarga(
      id: json['id'],
      noKk: json['no_kk'],
      alamat: json['alamat'],
      rt: json['rt'],
      rw: json['rw'],
      kepalaKeluargaId: json['kepala_keluarga_id'] != null
          ? int.tryParse(json['kepala_keluarga_id'].toString())
          : null,
      
    );
  }

  Map<String, dynamic> _toJson() => {
    'id': id,
    'no_kk': noKk,
    'alamat': alamat,
    'rt': rt,
    'rw': rw,
    'kepala_keluarga_id': kepalaKeluargaId,
    
  };
}
