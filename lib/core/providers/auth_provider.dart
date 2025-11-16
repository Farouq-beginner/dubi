// providers/auth_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../models/user_model.dart'; // Sesuaikan path jika perlu

class AuthProvider with ChangeNotifier {
  // --- STATE & TOOLS ---
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  final Dio _dio = Dio(
    BaseOptions(
      // PENTING:
      // Gunakan 10.0.2.2 untuk Android Emulator
      // Gunakan http://127.0.0.1:8000 jika menjalankan di Chrome (Web)
      // Pastikan server 'php artisan serve' Anda tetap berjalan!
      // Ganti '10.0.2.2' dengan '127.0.0.1' jika menjalankan di web (Chrome)
      baseUrl: 'http://127.0.0.1:8000p/api/',
      connectTimeout: Duration(seconds: 5),
      receiveTimeout: Duration(seconds: 3),
    ),
  );

  User? _user;
  String? _token;
  bool _isLoading = true;

  // --- GETTERS (Untuk dibaca UI) ---
  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _token != null && _user != null;
  Dio get dio => _dio; // Getter untuk service lain

  // --- CONSTRUCTOR ---
  AuthProvider() {
    _init();
  }

  // --- LOGIC METHODS ---

  Future<void> _init() async {
    try {
      final token = await _storage.read(key: 'authToken');
      final userJson = await _storage.read(key: 'userData');

      if (token != null && userJson != null) {
        _token = token;
        _user = User.fromJson(jsonDecode(userJson));
        _dio.options.headers['Authorization'] = 'Bearer $_token';
      }
    } catch (e) {
      print("Error saat _init auth: $e");
      await _storage.deleteAll();
      _token = null;
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// [PUBLIC] Handle Login User
  Future<void> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/login',
        data: {'email': email, 'password': password},
      );

      if (response.data['success'] == true) {
        // --- INI JALUR SUKSES ---
        // Kita HANYA parse 'user' jika sukses
        _user = User.fromJson(response.data['user']);
        _token = response.data['token'];

        await _storage.write(key: 'authToken', value: _token);
        await _storage.write(
          key: 'userData',
          value: jsonEncode(_user!.toJson()),
        );

        _dio.options.headers['Authorization'] = 'Bearer $_token';

        notifyListeners();
      }
    } on DioException catch (e) {
      // --- INI PERBAIKANNYA (JALUR GAGAL) ---
      // Jika login gagal (password salah), JANGAN parse user.
      // Cukup lemparkan (throw) pesan error-nya sebagai String.
      throw (e.response?.data['message'] ?? 'Login Gagal. Terjadi error.');
      // ------------------------------------
    } catch (e) {
      print("Login error (non-dio): $e");
      throw ('Terjadi kesalahan tidak dikenal saat login.');
    }
  }

  /// [PUBLIC] Refresh data user dari server agar halaman Profile bisa pull-to-refresh
  Future<void> refreshUser() async {
    try {
      // Coba endpoint umum '/me' lebih dulu
      final res = await _dio.get('/me');
      final data = res.data;
      User parsed;
      if (data is Map && data['user'] != null) {
        parsed = User.fromJson(data['user']);
      } else {
        parsed = User.fromJson(data);
      }
      _user = parsed;
      await _storage.write(key: 'userData', value: jsonEncode(_user!.toJson()));
      notifyListeners();
      return;
    } on DioException catch (_) {
      // Jika '/me' tidak ada, coba '/user'
      try {
        final res2 = await _dio.get('/user');
        final data2 = res2.data;
        User parsed2;
        if (data2 is Map && data2['user'] != null) {
          parsed2 = User.fromJson(data2['user']);
        } else {
          parsed2 = User.fromJson(data2);
        }
        _user = parsed2;
        await _storage.write(
          key: 'userData',
          value: jsonEncode(_user!.toJson()),
        );
        notifyListeners();
      } catch (e) {
        // Diamkan (backend mungkin tidak menyediakan endpoint ini)
        print('refreshUser fallback error: $e');
      }
    } catch (e) {
      print('refreshUser error: $e');
    }
  }

  /// [PUBLIC] Handle Registrasi User Baru
  Future<String> register({
    required String fullName,
    required String username,
    required String email,
    required String password,
    required String role,
    int? levelId,
  }) async {
    try {
      final response = await _dio.post(
        '/register',
        data: {
          'full_name': fullName,
          'username': username,
          'email': email,
          'password': password,
          'role': role,
          'level_id': levelId,
        },
      );

      // JALUR SUKSES: Kembalikan pesan sukses
      return response.data['message'];
    } on DioException catch (e) {
      // --- INI SUDAH BENAR (JALUR GAGAL) ---
      // Lemparkan pesan error-nya sebagai String.
      throw (e.response?.data['message'] ?? 'Register Gagal. Terjadi error.');
    } catch (e) {
      print("Register error (non-dio): $e");
      throw ('Terjadi kesalahan tidak dikenal saat register.');
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/logout');
    } catch (e) {
      print("Error logging out from API (tidak masalah): $e");
    } finally {
      _user = null;
      _token = null;
      await _storage.deleteAll();
      _dio.options.headers.remove('Authorization');
      notifyListeners();
    }
  }

  /// [PUBLIC] Handle Forgot Password
  Future<void> forgotPassword(String email) async {
    try {
      await _dio.post('/forgot-password', data: {'email': email});

      // Assuming success, no need to parse user or token
      // Backend should send reset link to email
    } on DioException catch (e) {
      throw (e.response?.data['message'] ??
          'Forgot password gagal. Terjadi error.');
    } catch (e) {
      print("Forgot password error (non-dio): $e");
      throw ('Terjadi kesalahan tidak dikenal saat forgot password.');
    }
  }
}
