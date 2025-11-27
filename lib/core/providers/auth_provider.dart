// lib/core/providers/auth_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  // --- STATE & TOOLS ---
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Dio _dio = Dio(
    BaseOptions(
      // PENTING:
      // Gunakan 10.0.2.2 untuk Android Emulator
      // Gunakan http://127.0.0.1:8000 jika menjalankan di Chrome (Web)
      // Pastikan server 'php artisan serve' Anda tetap berjalan!
      // Ganti '10.0.2.2' dengan '127.0.0.1' jika menjalankan di web (Chrome)
      baseUrl: 'http://192.168.1.3:8000/api/',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  User? _user;
  String? _token;
  bool _isLoading = true;
  // Update info controlled by AuthCheckScreen
  bool _updateRequired = false;
  Map<String, dynamic>? _updateInfo; // contains latest_build, download_url, changelog

  // --- GETTERS ---
  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _token != null && _user != null;
  Dio get dio => _dio;
  bool get updateRequired => _updateRequired;
  Map<String, dynamic>? get updateInfo => _updateInfo;

  // --- CONSTRUCTOR ---
  AuthProvider() {
    print("AuthProvider: Inisialisasi...");
    _init();
  }

  // Called by AuthCheckScreen to override update requirement state
  void setUpdateRequirement({required bool required, Map<String, dynamic>? info}) {
    _updateRequired = required;
    _updateInfo = info;
    notifyListeners();
  }

  Future<void> checkSession() async {
    if (_token == null) return;

    try {
      // Panggil endpoint ringan (misal: /user atau /server/session)
      // Jika endpoint ini mengembalikan 401, Interceptor akan otomatis menangkapnya
      await _dio.get('/user'); 
    } catch (e) {
      // Error akan ditangani oleh Interceptor atau diabaikan jika bukan 401
    }
  }

Future<bool> checkSessionValidity() async {
    try {
      // Panggil endpoint user
      final response = await _dio.get('/user');
      // Jika sukses (200), berarti valid
      return response.statusCode == 200;
    } catch (e) {
      // Jika error (401, 500, atau timeout), anggap tidak valid
      return false;
    }
  }

  

  // Helper Hapus Data Lokal
  Future<void> _clearLocalData() async {
    print("🧹 Membersihkan data lokal...");
    _user = null;
    _token = null;
    await _storage.deleteAll();
    _dio.options.headers.remove('Authorization');
    notifyListeners();
  }

  Future<void> _init() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final userJson = await _storage.read(key: 'user_data');

      if (token != null && userJson != null) {
        _token = token;
        _user = User.fromJson(jsonDecode(userJson));
        _dio.options.headers['Authorization'] = 'Bearer $_token';
        print("AuthProvider: User loaded from storage. Token: $_token");
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

  // [PUBLIC] Handle Login User
  Future<void> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/login',
        data: {'email': email, 'password': password},
      );

      if (response.data['success'] == true) {
        _user = User.fromJson(response.data['user']);
        _token = response.data['token'];

        await _storage.write(key: 'auth_token', value: _token);
        await _storage.write(
          key: 'user_data',
          value: jsonEncode(_user!.toJson()),
        );

        _dio.options.headers['Authorization'] = 'Bearer $_token';
        notifyListeners();
      }
    } on DioException catch (e) {
      throw (e.response?.data['message'] ?? 'Login Gagal. Terjadi error.');
    } catch (e) {
      print("Login error (non-dio): $e");
      throw ('Terjadi kesalahan tidak dikenal saat login.');
    }
  }


  /// [PUBLIC] Refresh data user dari server agar halaman Profile bisa pull-to-refresh
Future<void> refreshUser() async {
    try {
      // Panggil endpoint standar '/user'
      final response = await _dio.get('/user');
      
      if (response.statusCode == 200) {
        final data = response.data;
        
        // Logika parsing yang lebih aman
        // Backend Laravel biasanya mengembalikan objek user langsung,
        // tapi kadang dibungkus dalam 'data' atau 'user' tergantung konfigurasi resource.
        Map<String, dynamic> userMap;
        
        if (data['user'] != null) {
          userMap = data['user'];
        } else if (data['data'] != null) {
          userMap = data['data'];
        } else {
          userMap = data;
        }

        // Update state user
        _user = User.fromJson(userMap);

        // [PENTING] Simpan dengan key 'user_data' (harus sama dengan saat login/load)
        await _storage.write(
          key: 'user_data', 
          value: jsonEncode(_user!.toJson())
        );
        
        notifyListeners();
      }
    } catch (e) {
      print("Gagal refresh user: $e");
      // Opsional: Jangan logout user jika hanya gagal refresh (misal karena koneksi)
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

// Update fungsi logout agar menggunakan helper
Future<void> logout() async {
    try {
      await _dio.post('/logout');
    } catch (e) {
      print("Error logging out: $e");
    } finally {
      await _clearLocalData();
    }
  }
  
   Future<bool> loadUserFromStorage() async {
    // Logic sama dengan _init tapi publik
     await _init();
     return _token != null;
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
