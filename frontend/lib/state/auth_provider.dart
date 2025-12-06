import 'dart:io';
import 'package:flutter/material.dart';

import 'package:frontend/services/api_service.dart';
import 'package:frontend/models/user_model.dart';
import 'package:frontend/models/wallet_models.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService;

  AuthProvider(this._apiService);

  bool _isLoading = false;
  User? _user;

  bool get isLoading => _isLoading;
  User? get user => _user;
  bool get isAuthenticated => _user != null;

  // PERBAIKAN: Method internal untuk mengubah state dan memanggil listener
  void _setLoading(bool value) {
    _isLoading = value;
    // Panggil notifyListeners di microtask untuk menghindari setState during build
    Future.microtask(() => notifyListeners());
  }

  // Public method untuk mengaktifkan/menonaktifkan loading (Dipanggil dari widget lain)
  void setLoading(bool value) {
    _setLoading(value);
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

  // PERBAIKAN: Method yang Anda buat (refreshUserData) dipanggil di sini.
  Future<void> refreshUserData() async {
    // Kita tidak menggunakan _setLoading(true) karena ini dipanggil setelah transaksi sukses.
    final user = await _apiService.getUserDataFromStorage();
    if (user != null) {
      _user = user;
      // Panggil notifyListeners di microtask agar UI terupdate
      Future.microtask(() => notifyListeners());
    }
  }

  // FUNGSI BARU: UPDATE SALDO UI INSTAN (Mengganti objek Warga secara manual)
  void updateWallet(double newBalance) {
    if (_user == null || _user!.warga == null || _user!.warga!.wallet == null) {
      // Fallback: jika data belum lengkap, muat ulang penuh
      tryAutoLogin();
      return;
    }

    // [1] Buat objek Wallet baru dengan saldo yang diperbarui
    final currentWallet = _user!.warga!.wallet!;
    final updatedWallet = Wallet(
      id: currentWallet.id,
      wargaId: currentWallet.wargaId,
      desapayAccountNumber: currentWallet.desapayAccountNumber,
      balance: newBalance, // SALDO BARU
    );

    // [2] Buat objek Warga baru dengan Wallet yang diperbarui
    // Menggunakan konstruktor Warga secara manual (Copy data lama)
    final updatedWarga = Warga(
      id: _user!.warga!.id,
      nik: _user!.warga!.nik,
      namaLengkap: _user!.warga!.namaLengkap,
      rt: _user!.warga!.rt,
      rw: _user!.warga!.rw,
      tempatLahir: _user!.warga!.tempatLahir,
      tanggalLahir: _user!.warga!.tanggalLahir,
      jenisKelamin: _user!.warga!.jenisKelamin,
      alamatKtp: _user!.warga!.alamatKtp,
      agama: _user!.warga!.agama,
      statusPerkawinan: _user!.warga!.statusPerkawinan,
      pekerjaan: _user!.warga!.pekerjaan,
      kewarganegaraan: _user!.warga!.kewarganegaraan,
      keluargaId: _user!.warga!.keluargaId,
      statusDalamKeluarga: _user!.warga!.statusDalamKeluarga,
      noHp: _user!.warga!.noHp,
      fotoKtp: _user!.warga!.fotoKtp,
      keluarga: _user!.warga!.keluarga,
      user: _user!.warga!.user,
      wallet: updatedWallet, // <-- GANTI WALLET LAMA
    );

    // [3] Ganti objek User lama dengan User baru
    _user = User(
      id: _user!.id,
      email: _user!.email,
      role: _user!.role,
      warga: updatedWarga,
    );

    // [4] Kirim notifikasi update (UI segera berubah)
    notifyListeners();
  }
}
