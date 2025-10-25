// services/data_service.dart
import 'package:flutter/material.dart'; // <-- Ini adalah import yang bersih (tanpa 'hide')
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';

// Import semua model yang kita perlukan
import '../models/level_model.dart';
import '../models/subject_model.dart'; // Model Subject yang benar
import '../models/course_model.dart'; // Model Course yang sudah diperbaiki
import '../models/module_model.dart';
import '../models/quiz_model.dart';
import '../models/course_detail_model.dart';
import '../providers/auth_provider.dart';

class DataService {
  final BuildContext context;
  late Dio _dio; // Dio akan diambil dari AuthProvider

  DataService(this.context) {
    // Ambil Dio yang sudah terotentikasi dari AuthProvider
    // listen: false aman di sini karena ini ada di dalam constructor/fungsi
    _dio = Provider.of<AuthProvider>(context, listen: false).dio;
  }

  // --- Ambil data untuk Form ---
  Future<List<Level>> fetchLevels() async {
    final response = await _dio.get('/levels');
    List<dynamic> data = response.data['data'];
    return data.map((json) => Level.fromJson(json)).toList();
  }

  // Fungsi ini sekarang tidak akan error karena 'Subject' tidak lagi ambigu
  Future<List<Subject>> fetchSubjects() async {
    final response = await _dio.get('/subjects');
    List<dynamic> data = response.data['data'];
    return data.map((json) => Subject.fromJson(json)).toList();
  }

  // --- Ambil Kursus untuk Home Screen ---
  Future<List<Course>> fetchMyCourses() async {
    try {
      final response = await _dio.get('/home/my-courses');
      List<dynamic> data = response.data['data'];
      return data.map((json) => Course.fromJson(json)).toList();
    } on DioException catch (e) {
      throw (e.response?.data['message'] ?? 'Gagal memuat kursus');
    }
  }

  // --- Ambil Detail Kursus (Modul & Materi) ---
Future<CourseDetail> fetchCourseDetails(int courseId) async {
  try {
    final response = await _dio.get('/courses/$courseId');
    // 'data' adalah data kursus lengkap, kita parse jadi CourseDetail
    return CourseDetail.fromJson(response.data['data']);
  } on DioException catch (e) {
    throw (e.response?.data['message'] ?? 'Gagal memuat detail kursus');
  }
}

  // --- Kirim data Kursus Baru (Khusus Guru) ---
  Future<String> createCourse({
    required String title,
    required String description,
    required int levelId,
    required int subjectId,
  }) async {
    try {
      // Panggil API khusus Teacher
      final response = await _dio.post(
        '/teacher/courses', // Endpoint yang kita lindungi
        data: {
          'title': title,
          'description': description,
          'level_id': levelId,
          'subject_id': subjectId,
        },
      );
      return response.data['message']; // "Kursus baru berhasil ditambahkan!"
    } on DioException catch (e) {
      throw (e.response?.data['message'] ?? 'Gagal membuat kursus');
    }
  }

  Future<Module> createModule({
    required int courseId,
    required String title,
  }) async {
    try {
      final response = await _dio.post(
        '/teacher/courses/$courseId/modules',
        data: {'title': title},
      );
      // API mengembalikan data modul yang baru dibuat
      return Module.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw (e.response?.data['message'] ?? 'Gagal membuat modul');
    }
  }

  // --- [BARU] Membuat Lesson Baru ---
  Future<Module> createLesson({
    required int moduleId,
    required String title,
    required String contentType,
    String? contentBody,
  }) async {
    try {
      final response = await _dio.post(
        '/teacher/modules/$moduleId/lessons',
        data: {
          'title': title,
          'content_type': contentType,
          'content_body': contentBody,
        },
      );
      // API mengembalikan data MODUL yang sudah di-update (termasuk list lesson baru)
      return Module.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw (e.response?.data['message'] ?? 'Gagal membuat materi');
    }
  }

  // --- [BARU] Ambil Detail Kuis (Pertanyaan & Jawaban) ---
  Future<Quiz> fetchQuizDetails(int quizId) async {
    try {
      final response = await _dio.get('/quizzes/$quizId');
      // API mengembalikan data kuis lengkap di 'data'
      return Quiz.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw (e.response?.data['message'] ?? 'Gagal memuat kuis');
    }
  }

  // --- [BARU] Submit Jawaban Kuis ---
  // answers format: [{'question_id': 1, 'answer_id': 3}, {'question_id': 2, 'answer_id': 6}]
  Future<Map<String, dynamic>> submitQuiz(
    int quizId,
    List<Map<String, int>> answers,
  ) async {
    try {
      final response = await _dio.post(
        '/quizzes/$quizId/submit',
        data: {'answers': answers},
      );
      // API mengembalikan data skor di 'data'
      return response.data['data']; // (Map berisi score, total_questions, dll)
    } on DioException catch (e) {
      throw (e.response?.data['message'] ?? 'Gagal mengirim jawaban');
    }
  }
}
