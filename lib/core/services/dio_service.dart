// services/dio_service.dart
import 'package:dio/dio.dart';
import '../models/course_model.dart'; // Sesuaikan path jika perlu

class DioService {
  final Dio _dio = Dio(
    BaseOptions(
      // PENTING:
      // Gunakan 10.0.2.2 untuk Android Emulator
      // Gunakan http://127.0.0.1:8000 jika menjalankan di Chrome (Web)
      // Pastikan server 'php artisan serve' Anda tetap berjalan!
      baseUrl: 'http://127.0.0.1:8000/api/',
      connectTimeout: Duration(seconds: 5),
      receiveTimeout: Duration(seconds: 3),
    ),
  );

  // Fungsi untuk mengambil daftar kursus
  Future<List<Course>> fetchCoursesByLevel(int levelId) async {
    try {
      final response = await _dio.get('/courses/level/$levelId');

      if (response.statusCode == 200 && response.data['success'] == true) {
        List<dynamic> courseJsonList = response.data['data'];
        return courseJsonList.map((json) => Course.fromJson(json)).toList();
      } else {
        throw Exception('Gagal memuat kursus dari server');
      }
    } on DioException catch (e) {
      print('Dio error: $e');
      throw Exception('Error koneksi: ${e.message}');
    } catch (e) {
      print('Parse error: $e');
      throw Exception('Gagal memproses data');
    }
  }
}