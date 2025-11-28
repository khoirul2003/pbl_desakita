import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:frontend/models/user_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// INI ADALAH SATU-SATUNYA FILE SERVICE YANG ANDA BUTUHKAN

class ApiService {
  // --- PROPERTI & KONFIGURASI ---
  final String _baseUrlLaravel = "https://desa-kita.loca.lt/api";
  final String _baseUrlFastApi = "https://desa-kita-cv.loca.lt";

  final _storage = const FlutterSecureStorage();

  // Dio untuk request publik (login, register)
  final Dio _dioPublic = Dio();

  // Dio untuk request terproteksi (yang butuh token)
  late Dio _dioProtected;

  // --- KONSTRUKTOR ---
  ApiService() {
    _dioProtected = Dio();
    _dioProtected.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // 1. Tambahkan Header Bypass
          options.headers['Bypass-Tunnel-Reminder'] = 'true';
          // 2. Ambil token dari storage
          final token = await _storage.read(key: 'auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          print("Dio Interceptor Error: ${e.message}");
          return handler.next(e);
        },
      ),
    );

    // Tambahkan interceptor ke _dioPublic juga untuk bypass loca.lt
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
        data: {'face_features': features},
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
        data: {'face_features': features},
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

  // --- INI FUNGSI YANG ANDA BUTUHKAN ---
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
}
