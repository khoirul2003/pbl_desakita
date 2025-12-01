import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:frontend/models/user_model.dart';
import 'package:frontend/models/wallet_models.dart';
import 'package:frontend/models/iuran_model.dart';
import 'package:frontend/models/kegiatan_model.dart';
import 'package:frontend/models/acara_model.dart'; // Tambahkan untuk Manajemen Acara
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// INI ADALAH SATU-SATUNYA FILE SERVICE YANG DIGUNAKAN
// Mengurus Auth, Warga CRUD, CV/ML, Iuran, Kegiatan, Acara, dan Wallet.

class ApiService {
  // --- PROPERTI & KONFIGURASI (LOCA.LT) ---
  final String _baseUrlLaravel = "https://1fb0831adfd7.ngrok-free.app/api";

  final String _baseUrlFastApi = "https://c8c5591c47a3.ngrok-free.app";


  final _storage = const FlutterSecureStorage();

  // Dio untuk request publik (login, register)
  final Dio _dioPublic = Dio();

  // Dio untuk request terproteksi (yang butuh token)
  late Dio _dioProtected;

  // --- KONSTRUKTOR ---
  ApiService() {
    _dioProtected = Dio();

    // Interceptor untuk PROTECTED API (Menambahkan Token & Bypass Loca.lt)
    _dioProtected.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          options.headers['Bypass-Tunnel-Reminder'] = 'true';
          final token = await _storage.read(key: 'auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          print("Dio Interceptor Protected Error: ${e.message}");
          return handler.next(e);
        },
      ),
    );

    // Interceptor untuk PUBLIC API (Hanya Bypass Loca.lt)
    _dioPublic.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          options.headers['Bypass-Tunnel-Reminder'] = 'true';
          return handler.next(options);
        },
      ),
    );
  }

  // --- FUNGSI HELPER (INTERNAL) ---

  Future<User?> getUserDataFromStorage() async {
    final userString = await _storage.read(key: 'user_data');
    if (userString != null) {
      return User.fromJsonString(userString);
    }
    return null;
  }

  Future<void> _saveAuthData(Map<String, dynamic> data) async {
    final String token = data['token'];
    final User user = User.fromJson(data['user']);

    await _storage.write(key: 'auth_token', value: token);
    await _storage.write(key: 'user_data', value: user.toJsonString());
  }

  // --- FUNGSI AUTH SERVICE ---

  Future<bool> login(String email, String password) async {
    try {
      final response = await _dioPublic.post(
        '$_baseUrlLaravel/login',
        data: {'email': email, 'password': password},
      );
      if (response.statusCode == 200 && response.data['token'] != null) {
        await _saveAuthData(response.data);
        return true;
      }
      return false;
    } on DioException catch (e) {
      print("Error Login: ${e.response?.data}");
      return false;
    }
  }

  Future<bool> register(Map<String, dynamic> data) async {
    try {
      final response = await _dioPublic.post(
        '$_baseUrlLaravel/register',
        data: data,
      );
      if (response.statusCode == 201) {
        return await login(data['email'], data['password']);
      }
      return false;
    } on DioException catch (e) {
      print("Error Register: ${e.response?.data}");
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _dioProtected.post('$_baseUrlLaravel/v1/logout');
    } catch (e) {
      print("Error memanggil API logout (diabaikan): $e");
    } finally {
      await _storage.deleteAll();
    }
  }

  Future<bool> loginWithFace(List<double> features) async {
    try {
      final response = await _dioPublic.post(
        '$_baseUrlLaravel/login-face',
        // PENTING: Menggunakan jsonEncode untuk memenuhi validasi Laravel (String JSON)
        data: {'face_features': jsonEncode(features)},
      );
      if (response.statusCode == 200 && response.data['token'] != null) {
        await _saveAuthData(response.data);
        return true;
      }
      return false;
    } on DioException catch (e) {
      print("Error Login Wajah: ${e.response?.data}");
      return false;
    }
  }

  Future<bool> registerFace(List<double> features) async {
    try {
      final response = await _dioProtected.post(
        '$_baseUrlLaravel/v1/profile/register-face',
        // PENTING: Menggunakan jsonEncode untuk memenuhi validasi Laravel (String JSON)
        data: {'face_features': jsonEncode(features)},
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      print("Error Register Wajah: ${e.response?.data}");
      return false;
    }
  }

  // --- FUNGSI CV SERVICE (FASTAPI) ---

  Future<List<double>?> getFaceFeatures(File image) async {
    try {
      final String fileName = image.path.split('/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(image.path, filename: fileName),
      });
      final response = await _dioPublic.post(
        '$_baseUrlFastApi/extract-features',
        data: formData,
      );
      if (response.statusCode == 200 && response.data['features'] != null) {
        return List<double>.from(response.data['features']);
      }
      return null;
    } on DioException catch (e) {
      print("Error getFaceFeatures: ${e.response?.data}");
      return null;
    }
  }

  Future<bool> checkLiveness(List<File> frames) async {
    try {
      List<MultipartFile> fileList = [];
      for (var file in frames) {
        fileList.add(
          await MultipartFile.fromFile(
            file.path,
            filename: file.path.split('/').last,
          ),
        );
      }
      final formData = FormData.fromMap({'files': fileList});
      final response = await _dioPublic.post(
        '$_baseUrlFastApi/check-liveness',
        data: formData,
      );
      if (response.statusCode == 200 && response.data['liveness'] != null) {
        return response.data['liveness'];
      }
      return false;
    } on DioException catch (e) {
      print("Error checkLiveness: ${e.response?.data}");
      return false;
    }
  }

  // --- FUNGSI WARGA SERVICE (ADMIN) ---

  Future<List<Warga>> getManajemenWarga({String? search}) async {
    try {
      final response = await _dioProtected.get(
        '$_baseUrlLaravel/v1/warga',
        queryParameters: {'search': search},
      );
      if (response.statusCode == 200 && response.data['data'] != null) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => Warga.fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      print("Error getManajemenWarga: ${e.response?.data}");
      rethrow;
    }
  }

  Future<Warga?> createManajemenWarga(Map<String, dynamic> data) async {
    try {
      final response = await _dioProtected.post(
        '$_baseUrlLaravel/v1/warga',
        data: data,
      );
      if (response.statusCode == 201 && response.data != null) {
        return Warga.fromJson(response.data);
      }
      return null;
    } on DioException catch (e) {
      print("Error createManajemenWarga: ${e.response?.data}");
      rethrow;
    }
  }

  Future<Warga?> getDetailWarga(int wargaId) async {
    try {
      final response = await _dioProtected.get(
        '$_baseUrlLaravel/v1/warga/$wargaId',
      );
      if (response.statusCode == 200 && response.data != null) {
        return Warga.fromJson(response.data);
      }
      return null;
    } on DioException catch (e) {
      print("Error getDetailWarga: ${e.response?.data}");
      return null;
    }
  }

  Future<Warga?> updateManajemenWarga(
    int wargaId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dioProtected.put(
        '$_baseUrlLaravel/v1/warga/$wargaId',
        data: data,
      );
      if (response.statusCode == 200 && response.data != null) {
        return Warga.fromJson(response.data);
      }
      return null;
    } on DioException catch (e) {
      print("Error updateManajemenWarga: ${e.response?.data}");
      rethrow;
    }
  }

  Future<bool> deleteWarga(int wargaId) async {
    try {
      final response = await _dioProtected.delete(
        '$_baseUrlLaravel/v1/warga/$wargaId',
      );
      return response.statusCode == 204;
    } on DioException catch (e) {
      print("Error deleteWarga: ${e.response?.data}");
      return false;
    }
  }

  // --- FUNGSI IURAN SERVICE (ADMIN) ---

  Future<List<Iuran>> getManajemenIuran({String? search}) async {
    try {
      final response = await _dioProtected.get(
        '$_baseUrlLaravel/v1/iuran',
        queryParameters: {'search': search},
      );
      if (response.statusCode == 200 && response.data['data'] != null) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => Iuran.fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      print("Error getManajemenIuran: ${e.response?.data}");
      rethrow;
    }
  }

  Future<bool> createIuran(Map<String, dynamic> data) async {
    try {
      final response = await _dioProtected.post(
        '$_baseUrlLaravel/v1/iuran',
        data: data,
      );
      return response.statusCode == 201;
    } on DioException catch (e) {
      print("Error createIuran: ${e.response?.data}");
      return false;
    }
  }

  Future<bool> updateIuran(int iuranId, Map<String, dynamic> data) async {
    try {
      final response = await _dioProtected.put(
        '$_baseUrlLaravel/v1/iuran/$iuranId',
        data: data,
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      print("Error updateIuran: ${e.response?.data}");
      return false;
    }
  }

  Future<bool> deleteIuran(int iuranId) async {
    try {
      final response = await _dioProtected.delete(
        '$_baseUrlLaravel/v1/iuran/$iuranId',
      );
      return response.statusCode == 204;
    } on DioException catch (e) {
      print("Error deleteIuran: ${e.response?.data}");
      return false;
    }
  }

  // --- FUNGSI KEGIATAN SERVICE (ADMIN) ---

  Future<List<Kegiatan>> getManajemenKegiatan({String? search}) async {
    try {
      final response = await _dioProtected.get(
        '$_baseUrlLaravel/v1/kegiatan',
        queryParameters: {'search': search},
      );
      if (response.statusCode == 200 && response.data['data'] != null) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => Kegiatan.fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      print("Error getManajemenKegiatan: ${e.response?.data}");
      rethrow;
    }
  }

  Future<bool> createKegiatan(Map<String, dynamic> data) async {
    try {
      final response = await _dioProtected.post(
        '$_baseUrlLaravel/v1/kegiatan',
        data: data,
      );
      return response.statusCode == 201;
    } on DioException catch (e) {
      print("Error createKegiatan: ${e.response?.data}");
      return false;
    }
  }

  Future<bool> updateKegiatan(int kegiatanId, Map<String, dynamic> data) async {
    try {
      final response = await _dioProtected.put(
        '$_baseUrlLaravel/v1/kegiatan/$kegiatanId',
        data: data,
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      print("Error updateKegiatan: ${e.response?.data}");
      return false;
    }
  }

  Future<bool> deleteKegiatan(int kegiatanId) async {
    try {
      final response = await _dioProtected.delete(
        '$_baseUrlLaravel/v1/kegiatan/$kegiatanId',
      );
      return response.statusCode == 204;
    } on DioException catch (e) {
      print("Error deleteKegiatan: ${e.response?.data}");
      return false;
    }
  }

  // --- FUNGSI ACARA SERVICE (ADMIN) ---

  Future<List<Acara>> getManajemenAcara({String? search}) async {
    try {
      final response = await _dioProtected.get(
        '$_baseUrlLaravel/v1/acara',
        queryParameters: {'search': search},
      );
      if (response.statusCode == 200 && response.data['data'] != null) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => Acara.fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      print("Error getManajemenAcara: ${e.response?.data}");
      rethrow;
    }
  }

  Future<bool> createAcara(Map<String, dynamic> data) async {
    try {
      final response = await _dioProtected.post(
        '$_baseUrlLaravel/v1/acara',
        data: data,
      );
      return response.statusCode == 201;
    } on DioException catch (e) {
      print("Error createAcara: ${e.response?.data}");
      return false;
    }
  }

  Future<bool> updateAcara(int acaraId, Map<String, dynamic> data) async {
    try {
      final response = await _dioProtected.put(
        '$_baseUrlLaravel/v1/acara/$acaraId',
        data: data,
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      print("Error updateAcara: ${e.response?.data}");
      return false;
    }
  }

  Future<bool> deleteAcara(int acaraId) async {
    try {
      final response = await _dioProtected.delete(
        '$_baseUrlLaravel/v1/acara/$acaraId',
      );
      return response.statusCode == 204;
    } on DioException catch (e) {
      print("Error deleteAcara: ${e.response?.data}");
      return false;
    }
  }

  // --- FUNGSI DESAPAY / WALLET SERVICE ---

  /// [WALLET] Mengambil Saldo dan 10 Transaksi Terakhir
  Future<Map<String, dynamic>?> getWalletData() async {
    try {
      final response = await _dioProtected.get(
        '$_baseUrlLaravel/v1/wallet/balance',
      );

      if (response.statusCode == 200 && response.data['wallet'] != null) {
        final List<Transaction> transactions =
            (response.data['transactions'] as List)
                .map((json) => Transaction.fromJson(json))
                .toList();

        return {
          'wallet': Wallet.fromJson(response.data['wallet']),
          'transactions': transactions,
        };
      }
      return null;
    } on DioException catch (e) {
      print("Error getWalletData: ${e.response?.data}");
      return null;
    }
  }

  /// [WALLET] Simulasi Top Up Saldo
  Future<double?> topUpWallet(double amount) async {
    try {
      final response = await _dioProtected.post(
        '$_baseUrlLaravel/v1/wallet/topup',
        data: {'amount': amount},
      );
      if (response.statusCode == 200 && response.data['new_balance'] != null) {
        return double.tryParse(response.data['new_balance'].toString());
      }
      return null;
    } on DioException catch (e) {
      print("Error topUpWallet: ${e.response?.data}");
      return null;
    }
  }

  Future addKegiatan(Map<String, String> data) async {}
}
