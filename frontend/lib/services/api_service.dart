import 'dart:convert';
import 'dart:io'; 
import 'package:dio/dio.dart';

import 'package:frontend/models/user_model.dart'; 
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  
  
  
  
  final String _baseUrlLaravel = "https:desa-kita.loca.lt/api";
  final String _baseUrlFastApi = "https:desa-kita-cv.loca.lt";
  

  final _storage = const FlutterSecureStorage();

  
  
  final Dio _dioPublic = Dio();

  
  late Dio _dioProtected;

  
  ApiService() {
    
    _dioProtected = Dio();
    _dioProtected.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          
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
      
      final response = await _dioPublic.post('$_baseUrlLaravel/register', data: data);

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
      print("Error Logout: $e");
    } finally {
      
      await _storage.deleteAll();
    }
  }

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

  

  
  
  Future<List<Warga>> getManajemenWarga({int page = 1, String? search}) async {
    try {
      final params = {
        'page': page,
        if (search != null && search.isNotEmpty) 'search': search,
      };

      
      final response = await _dioProtected.get(
        '$_baseUrlLaravel/v1/warga',
        queryParameters: params,
      );

      if (response.statusCode == 200 && response.data['data'] != null) {
        
        List<dynamic> wargaListJson = response.data['data'];
        return wargaListJson.map((json) => Warga.fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      print("Error getManajemenWarga: ${e.response?.data}");
      return []; 
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
      return null;
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

  

  
  Future<List<double>?> getFaceFeatures(File image) async {
    try {
      String fileName = image.path.split('/').last;
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(image.path, filename: fileName),
      });

      final response = await _dioPublic.post(
        '$_baseUrlFastApi/extract-features',
        data: formData,
      );

      if (response.statusCode == 200 && response.data['features'] != null) {
        
        List<dynamic> featureList = response.data['features'];
        return featureList.map((e) => e as double).toList();
      }
      return null;
    } on DioException catch (e) {
      print("Error getFaceFeatures: ${e.response?.data}");
      return null;
    }
  }

  
  Future<bool> checkLiveness(List<File> frames) async {
    try {
      FormData formData = FormData();
      for (var frame in frames) {
        String fileName = frame.path.split('/').last;
        formData.files.add(MapEntry(
          "files", 
          await MultipartFile.fromFile(frame.path, filename: fileName),
        ));
      }

      final response = await _dioPublic.post(
        '$_baseUrlFastApi/check-liveness',
        data: formData,
      );

      if (response.statusCode == 200 && response.data['liveness'] != null) {
        return response.data['liveness'] as bool;
      }
      return false;
    } on DioException catch (e) {
      print("Error checkLiveness: ${e.response?.data}");
      return false;
    }
  }

  

  
  Future<bool> registerFace(List<double> features) async {
    try {
      
      String featuresJson = json.encode(features);

      final response = await _dioProtected.post( 
        '$_baseUrlLaravel/v1/profile/register-face',
        data: {'face_features': featuresJson},
      );

      return response.statusCode == 200;
    } on DioException catch (e) {
      print("Error registerFace: ${e.response?.data}");
      return false;
    }
  }

  
  Future<bool> loginWithFace(List<double> features) async {
    try {
      String featuresJson = json.encode(features);

      final response = await _dioPublic.post( 
        '$_baseUrlLaravel/login-face',
        data: {'face_features': featuresJson},
      );

      if (response.statusCode == 200 && response.data['token'] != null) {
        
        await _saveAuthData(response.data);
        return true;
      }
      return false;
    } on DioException catch (e) {
      print("Error loginWithFace: ${e.response?.data}");
      return false;
    }
  }
}