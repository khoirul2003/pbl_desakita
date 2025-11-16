import 'dart:io';
import 'package:flutter/material.dart';

import 'package:frontend/services/api_service.dart';
import 'package:frontend/models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService;

  AuthProvider(this._apiService);

  bool _isLoading = false;
  User? _user;

  bool get isLoading => _isLoading;
  User? get user => _user;
  bool get isAuthenticated => _user != null;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners(); 
  }

  
  Future<bool> tryAutoLogin() async {
    _setLoading(true);
    final user = await _apiService.getUserDataFromStorage();
    if (user == null) {
      _setLoading(false);
      return false; 
    }

    _user = user;
    _setLoading(false);
    return true; 
  }

  
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    final success = await _apiService.login(email, password);
    if (success) {
      
      _user = await _apiService.getUserDataFromStorage();
    }
    _setLoading(false);
    return success;
  }

  
  Future<bool> register(Map<String, dynamic> data) async {
    _setLoading(true);
    final success = await _apiService.register(data);
    if (success) {
      
      _user = await _apiService.getUserDataFromStorage();
    }
    _setLoading(false);
    return success;
  }

  
  Future<void> logout() async {
    _setLoading(true);
    await _apiService.logout();
    _user = null; 
    _setLoading(false);
  }

  
  
  Future<String?> registerFace(File image) async {
    _setLoading(true);
    String? error;

    try {
      
      final features = await _apiService.getFaceFeatures(image);

      if (features == null) {
        error = "Wajah tidak terdeteksi. Coba lagi.";
      } else {
        
        final success = await _apiService.registerFace(features);
        if (!success) {
          error = "Gagal menyimpan data wajah ke server.";
        }
      }
    } catch (e) {
      error = "Terjadi kesalahan: $e";
    }

    _setLoading(false);
    return error; 
  }

  

  
  
  
  Future<String?> loginWithFace(List<File> frames, File bestFrame) async {
    _setLoading(true);
    String? error;

    try {
      
      final isLive = await _apiService.checkLiveness(frames);

      if (!isLive) {
        error = "Deteksi Liveness Gagal. Pastikan Anda berkedip.";
      } else {
        
        final features = await _apiService.getFaceFeatures(bestFrame);

        if (features == null) {
          error = "Wajah tidak terdeteksi. Coba lagi.";
        } else {
          
          final success = await _apiService.loginWithFace(features);
          if (success) {
            
            _user = await _apiService.getUserDataFromStorage();
            error = null; 
          } else {
            error = "Wajah tidak dikenali atau tidak terdaftar.";
          }
        }
      }
    } catch (e) {
      error = "Terjadi kesalahan: $e";
    }

    _setLoading(false);
    return error; 
  }
}
