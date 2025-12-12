import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:frontend/models/user_model.dart';
import 'package:frontend/models/iuran_model.dart';
import 'package:frontend/models/kegiatan_model.dart';
import 'package:frontend/models/acara_model.dart';
import 'package:frontend/models/keuangan_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend/models/wallet_models.dart';
import 'package:frontend/models/tagihan_iuran_model.dart';

class ApiService {
  // --- PROPERTI & KONFIGURASI (NGROK/PUBLIC ACCESS) ---
  final String _baseUrlLaravel = "https://64df3290146c.ngrok-free.app/api";
  final String _baseUrlFastApi = "https://b6d8ff767f85.ngrok-free.app";

  final _storage = const FlutterSecureStorage();
  final Dio _dioPublic = Dio();
  late Dio _dioProtected;

  ApiService() {
    _dioProtected = Dio();

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

     _dioPublic.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          options.headers['Bypass-Tunnel-Reminder'] = 'true';
          return handler.next(options);
        },
      ),
    );
  }

  Dio get dioProtected => _dioProtected;
  String get baseUrlLaravel => _baseUrlLaravel;

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

        data: {'face_features': jsonEncode(features)},
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      print("Error Register Wajah: ${e.response?.data}");
      return false;
    }
  }

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

  Future<List<Warga>> getManajemenWarga({String? search, String? rt, String? rw}) async {
    try {
      final Map<String, dynamic> params = {};

      if (search != null && search.isNotEmpty) {
        params['search'] = search;
      }
      if (rt != null && rt.isNotEmpty) {
        params['rt'] = rt;
      }
      if (rw != null && rw.isNotEmpty) {
        params['rw'] = rw;
      }

      final response = await _dioProtected.get(
        '$_baseUrlLaravel/v1/warga',
        queryParameters: params,
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

  Future<List<Iuran>> getManajemenIuran({String? search, String? rt, String? rw}) async {
    try {
      final Map<String, dynamic> params = {};

      if (search != null && search.isNotEmpty) {
        params['search'] = search;
      }
      if (rt != null && rt.isNotEmpty) {
        params['rt'] = rt;
      }
      if (rw != null && rw.isNotEmpty) {
        params['rw'] = rw;
      }

      final response = await _dioProtected.get(
        '$_baseUrlLaravel/v1/iuran',
        queryParameters: params, 
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

  Future<List<Keuangan>> getManajemenKeuangan() async {
    try {
      final response = await _dioProtected.get('$_baseUrlLaravel/v1/keuangan');
      if (response.statusCode == 200 && response.data['data'] != null) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => Keuangan.fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      print("Error getManajemenKeuangan: ${e.response?.data}");
      rethrow;
    }
  }


  Future<WalletSummary?> getWalletSummary() async {
    try {
      final response = await _dioProtected.get(
        '$_baseUrlLaravel/v1/wallet/balance',
      );

      if (response.statusCode == 200 &&
          response.data != null &&
          response.data['wallet'] != null) {
        return WalletSummary.fromJson(response.data);
      }
      return null;
    } on DioException catch (e) {
      print("Error getWalletSummary: ${e.response?.data}");
      rethrow;
    }
  }

  Future<double?> topUpWallet(double amount) async {
    try {
      final response = await _dioProtected.post(
        '$_baseUrlLaravel/v1/wallet/topup',
        data: {'amount': amount},
      );
      if (response.statusCode == 200 &&
          response.data != null &&
          response.data['new_balance'] != null) {
        return double.tryParse(response.data['new_balance'].toString());
      }
      return null;
    } on DioException catch (e) {
      print("Error topUpWallet: ${e.response?.data}");
      rethrow;
    }
  }

  Future<double?> transferWallet({
    required String accountNumberReceiver,
    required double amount,
    String? notes,
  }) async {
    try {
      final response = await _dioProtected.post(
        '$_baseUrlLaravel/v1/wallet/transfer',
        data: {
          'account_number_receiver': accountNumberReceiver,
          'amount': amount,
          'notes': notes,
        },
      );
      if (response.statusCode == 200 &&
          response.data != null &&
          response.data['new_balance'] != null) {
        return double.tryParse(response.data['new_balance'].toString());
      }
      return null;
    } on DioException catch (e) {
      print("Error transferWallet: ${e.response?.data}");
      rethrow;
    }
  }

  Future<double?> payPPOB({
    required double amount,
    required String productName,
    required String targetNumber,
    double fee = 0,
  }) async {
    try {
      final response = await _dioProtected.post(
        '$_baseUrlLaravel/v1/wallet/pay-ppob',
        data: {
          'amount': amount,
          'product_name': productName,
          'target_number': targetNumber,
          'fee': fee,
        },
      );
      if (response.statusCode == 200 &&
          response.data != null &&
          response.data['new_balance'] != null) {
        return double.tryParse(response.data['new_balance'].toString());
      }
      return null;
    } on DioException catch (e) {
      print("Error payPPOB: ${e.response?.data}");
      rethrow;
    }
  }

  Future<List<TagihanIuran>> getTagihanIuranWarga() async {
    try {
      final response = await _dioProtected.get(
        '$_baseUrlLaravel/v1/fitur/tagihan',
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;

        List<dynamic> listJson;
        if (data is Map && data['data'] != null) {
          listJson = data['data'] as List<dynamic>;
        } else if (data is List) {
          listJson = data;
        } else {
          return [];
        }

        return listJson
            .map((e) => TagihanIuran.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      print("Error getTagihanIuranWarga: ${e.response?.data}");
      rethrow;
    }
  }

  Future<bool> bayarTagihanIuran(int tagihanId) async {
    try {
      final response = await _dioProtected.post(
        '$_baseUrlLaravel/v1/fitur/tagihan/$tagihanId/bayar',
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      print("Error bayarTagihanIuran: ${e.response?.data}");
      rethrow;
    }
  }

  Future<Response> getBalanceAndTransactions() async {
    try {
      final response = await _dioProtected.get(
        '$_baseUrlLaravel/v1/wallet/balance',
      );
      return response;
    } on DioException catch (e) {
      print("Error getBalanceAndTransactions: ${e.response?.data}");
      rethrow;
    }
  }

    Future<User?> fetchProfile() async {
    try {
      final response = await _dioProtected.get('$_baseUrlLaravel/v1/profile');

      if (response.statusCode == 200 && response.data != null) {
        final user = User.fromJson(response.data);

        await _storage.write(key: 'user_data', value: user.toJsonString());

        return user;
      }
      return null;
    } on DioException catch (e) {
      print("Error fetchProfile: ${e.response?.data}");
      rethrow;
    }
  }

  Future<User?> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _dioProtected.put(
        '$_baseUrlLaravel/v1/profile',
        data: data,
      );

      if (response.statusCode == 200 && response.data != null) {
        final userJson =
            response.data['user'] ?? response.data;
        final user = User.fromJson(userJson);

        await _storage.write(key: 'user_data', value: user.toJsonString());

        return user;
      }
      return null;
    } on DioException catch (e) {
      print("Error updateProfile: ${e.response?.data}");
      rethrow;
    }
  }

  Future<String?> uploadProfilePhoto(File file) async {
    try {
      final fileName = file.path.split('/').last;

      final formData = FormData.fromMap({
        'foto': await MultipartFile.fromFile(file.path, filename: fileName),
      });

      final res = await _dioProtected.post(
        '$_baseUrlLaravel/v1/profile/upload-photo',
        data: formData,
      );

      if (res.statusCode == 200) {
        return res.data['foto_url'];
      }

      return null;
    } on DioException catch (e) {
      print("Upload Foto Error: ${e.response?.data}");
      return null;
    }
  }


}
