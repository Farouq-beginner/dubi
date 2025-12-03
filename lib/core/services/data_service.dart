// services/data_service.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'dart:io';

// Import semua model dari core
import '../models/notification_model.dart';
import '../models/user_model.dart';
import '../models/level_model.dart';
import '../models/subject_model.dart';
import '../models/course_model.dart';
import '../models/module_model.dart';
import '../models/quiz_model.dart';
import '../models/question_model.dart';
import '../models/course_detail_model.dart';
import '../models/student_dashboard_model.dart';
import '../models/sempoa_progress_model.dart';
import '../models/leaderboard_model.dart';

import '../providers/auth_provider.dart';

class DataService {
  final BuildContext context;
  late Dio _dio;

  DataService(this.context) {
    // Ambil Dio yang sudah terotentikasi dari AuthProvider
    _dio = Provider.of<AuthProvider>(context, listen: false).dio;
  }

  String _handleDioError(DioException e, String defaultMessage) {
    // Cek jika respons adalah Map DAN memiliki 'message'
    if (e.response != null &&
        e.response!.data is Map &&
        e.response!.data.containsKey('message')) {
      return e.response!.data['message'].toString();
    }

    // Jika respons adalah 403 (HTML), beri pesan generik
    if (e.response?.statusCode == 403) {
      return 'Akses ditolak. Anda tidak memiliki izin.';
    }

    // Jika 500 atau error lainnya (HTML), beri pesan server error
    if (e.response?.statusCode == 500) {
      return 'Terjadi kesalahan internal pada server.';
    }

    return defaultMessage; // Fallback
  }

  // ... (fungsi fetch, CRUD Teacher, dan Admin Anda) ...

  // Cek apakah server bisa dihubungi
  Future<bool> checkServerConnection() async {
    try {
      _dio.options.connectTimeout = const Duration(seconds: 5); // Timeout cepat
      final response = await _dio.get('/server/status');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Cek apakah token saat ini masih valid
  Future<bool> checkSessionValidity() async {
    try {
      final response = await _dio.get('/server/session');
      return response.data['valid'] == true;
    } catch (e) {
      return false; // Token invalid atau expired
    }
  }

  // Logout device lain
  Future<String> logoutOtherDevices() async {
    // Implementasi khusus: Biasanya butuh login ulang untuk dapat token baru
    // Untuk simplifikasi, kita arahkan user logout lokal dulu
    return "Silakan login kembali untuk mereset sesi.";
  }

  // ------------------------------------------------------------------
  // --- PROFILE Operations (Foto & Password) -------------------------
  // ------------------------------------------------------------------

  // [PERBAIKAN] 1. Upload Foto Profil
  Future<String> uploadProfilePhoto(List<int> bytes, String filename) async {
    try {
      FormData formData = FormData.fromMap({
        "photo": MultipartFile.fromBytes(bytes, filename: filename),
      });

      final response = await _dio.post('/profile/update-photo', data: formData);

      // Pastikan response data valid sebelum akses
      if (response.data != null && response.data['data'] != null) {
        return response.data['data']['url'].toString();
      }
      throw 'Format respon server tidak valid.';
    } on DioException catch (e) {
      print("Upload Error: ${e.response?.data}");
      throw _handleDioError(e, 'Gagal mengunggah foto profil.');
    } catch (e) {
      print("File Error: $e");
      throw "Gagal memproses file gambar.";
    }
  }

  // 1. Request Kode Verifikasi ke Email
  Future<String> sendPasswordCode() async {
    // Simpan timeout asli agar tidak mengganggu request lain yang berjalan paralel
    final originalConnect = _dio.options.connectTimeout;
    final originalSend = _dio.options.sendTimeout;
    final originalReceive = _dio.options.receiveTimeout;
    try {
      // Perlu perpanjang SEMUA: connectTimeout (fase handshake), sendTimeout (mengirim body), receiveTimeout (menunggu respons)
      // Jika hanya receiveTimeout, koneksi bisa gagal lebih dulu di connectTimeout 5 detik.
      _dio.options.connectTimeout = const Duration(seconds: 30);
      _dio.options.sendTimeout = const Duration(seconds: 30);
      _dio.options.receiveTimeout = const Duration(seconds: 30);

      // Alternatif yang lebih aman (tidak ubah global) adalah Options(...), tapi kita sudah simpan & restore.
      final response = await _dio.post(
        '/profile/send-password-code',
        // Per-request Options (tanpa connectTimeout karena hanya tersedia di BaseOptions)
        options: Options(
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      // Cek apakah ada key 'message'
      if (response.data is Map && response.data['message'] != null) {
        return response.data['message'].toString();
      }
      return 'Kode berhasil dikirim.'; // Fallback jika struktur tidak sesuai
    } on DioException catch (e) {
      // Jika timeout terjadi, kemungkinan email tetap diproses server (non-blocking)
      if (e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionTimeout) {
        throw 'Koneksi lambat, silakan cek email. Jika belum ada, coba lagi.';
      }
      throw _handleDioError(e, 'Gagal mengirim kode verifikasi.');
    } finally {
      // Kembalikan konfigurasi global ke nilai sebelumnya agar request lain tetap cepat
      _dio.options.connectTimeout = originalConnect;
      _dio.options.sendTimeout = originalSend;
      _dio.options.receiveTimeout = originalReceive;
    }
  }

  // 2. Reset Password (Kirim Kode + Password Baru)
  Future<String> resetPasswordWithCode({
    required String code,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final response = await _dio.post(
        '/profile/reset-password-with-code',
        data: {
          'code': code,
          'password': newPassword,
          'password_confirmation': confirmPassword,
        },
      );
      return response.data['message'];
    } on DioException catch (e) {
      throw _handleDioError(e, 'Gagal mengubah password.');
    }
  }

  // -------------------------------------------------------------------
  // --- PUBLIC FORGOT PASSWORD ---------------------------
  // -------------------------------------------------------------------

  Future<String> forgotPasswordSendCode(String email) async {
    try {
      _dio.options.sendTimeout = const Duration(seconds: 30);
      final response = await _dio.post(
        '/forgot-password',
        data: {'email': email},
      );
      return response.data['message'];
    } on DioException catch (e) {
      throw _handleDioError(e, 'Gagal mengirim kode');
    }
  }

  Future<String> forgotPasswordReset({
    required String email,
    required String code,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final response = await _dio.post(
        '/reset-password',
        data: {
          'email': email,
          'code': code,
          'password': newPassword,
          'password_confirmation': confirmPassword,
        },
      );
      return response.data['message'];
    } on DioException catch (e) {
      throw _handleDioError(e, 'Gagal mereset password');
    }
  }

  // ------------------------------------------------------------------
  // --- READ Operations (Umum & Siswa) --------------------------------
  // ------------------------------------------------------------------

  Future<List<Level>> fetchLevels() async {
    try {
      final response = await _dio.get('/levels');
      List<dynamic> data = response.data['data'];
      return data.map((json) => Level.fromJson(json)).toList();
    } on DioException catch (e) {
      // Pesan generik agar UI tidak menampilkan DioException mentah
      throw _handleDioError(e, 'Gagal memuat data.');
    }
  }

  Future<List<Subject>> fetchSubjects() async {
    try {
      final response = await _dio.get('/subjects');
      List<dynamic> data = response.data['data'];
      return data.map((json) => Subject.fromJson(json)).toList();
    } on DioException catch (e) {
      // Pesan generik agar UI tidak menampilkan DioException mentah
      throw _handleDioError(e, 'Gagal memuat data.');
    }
  }

  Future<List<Course>> fetchMyCourses() async {
    try {
      final response = await _dio.get('/home/my-courses');
      List<dynamic> data = response.data['data'];
      return data.map((json) => Course.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e, 'Gagal memuat course.');
    }
  }

  Future<CourseDetail> fetchCourseDetails(int courseId) async {
    try {
      final response = await _dio.get('/courses/$courseId');
      return CourseDetail.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e, 'Gagal memuat detail kursus');
    }
  }

  // --- Ambil Detail Kuis (UNTUK SISWA - menyembunyikan jawaban) ---
  Future<Quiz> fetchQuizDetails(int quizId) async {
    try {
      final response = await _dio.get('/quizzes/$quizId');
      return Quiz.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e, 'Gagal memuat kuis');
    }
  }

  // --- [BARU] Ambil Detail Kuis (UNTUK GURU - menampilkan jawaban) ---
  Future<Quiz> fetchQuizDetailsForTeacher(int quizId) async {
    try {
      final response = await _dio.get(
        '/teacher/quizzes/$quizId',
      ); // <-- Panggil Rute Guru
      return Quiz.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e, 'Gagal memuat editor kuis');
    }
  }

  Future<Map<String, dynamic>> submitQuiz(
    int quizId,
    List<Map<String, int>> answers,
  ) async {
    try {
      final response = await _dio.post(
        '/quizzes/$quizId/submit',
        data: {'answers': answers},
      );
      return response.data['data'];
    } on DioException catch (e) {
      throw _handleDioError(e, 'Gagal mengirim jawaban');
    }
  }

  // ------------------------------------------------------------------
  // --- TEACHER CRUD Operations (Create) ------------------------------
  // ------------------------------------------------------------------

  Future<Course> createCourse({
    required String title,
    required String description,
    required int levelId,
    required int subjectId,
  }) async {
    try {
      final response = await _dio.post(
        '/teacher/courses',
        data: {
          'title': title,
          'description': description,
          'level_id': levelId,
          'subject_id': subjectId,
        },
      );
      return Course.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e, 'Gagal membuat kursus');
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
      return Module.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e, 'Gagal membuat modul');
    }
  }

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
      return Module.fromJson(
        response.data['data'],
      ); // Mengembalikan Module yang di-update
    } on DioException catch (e) {
      throw _handleDioError(e, 'Gagal menambah materi');
    }
  }

  Future<Quiz> createQuiz({
    required int courseId,
    required String title,
    required String description,
    int? moduleId,
    int? duration,
  }) async {
    try {
      final response = await _dio.post(
        '/teacher/courses/$courseId/quizzes',
        data: {
          'title': title,
          'description': description,
          'module_id': moduleId,
          'duration': duration,
        },
      );
      return Quiz.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e, 'Gagal membuat kuis');
    }
  }

  Future<Question> createQuestion({
    required int quizId,
    required String questionText,
    required String questionType,
    required List<Map<String, dynamic>> answers,
  }) async {
    try {
      final response = await _dio.post(
        '/teacher/quizzes/$quizId/questions',
        data: {
          'question_text': questionText,
          'question_type': questionType,
          'answers': answers,
        },
      );
      return Question.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e, 'Gagal membuat pertanyaan');
    }
  }

  // ------------------------------------------------------------------
  // --- TEACHER CRUD Operations (Update & Delete) ---------------------
  // ------------------------------------------------------------------

  // --- COURSE ---
  Future<String> updateCourse({
    required int courseId,
    required String title,
    required String description,
    required int levelId,
    required int subjectId,
  }) async {
    try {
      final response = await _dio.put(
        '/teacher/courses/$courseId',
        data: {
          'title': title,
          'description': description,
          'level_id': levelId,
          'subject_id': subjectId,
        },
      );
      return response.data['message'];
    } on DioException catch (e) {
      throw _handleDioError(e, 'Gagal memperbarui kursus');
    }
  }

  Future<String> deleteCourse(int courseId) async {
    try {
      final response = await _dio.delete('/teacher/courses/$courseId');
      return response.data['message'];
    } on DioException catch (e) {
      throw _handleDioError(e, 'Gagal menghapus kursus');
    }
  }

  // --- MODULE ---
  Future<String> updateModule({
    required int courseId,
    required int moduleId,
    required String title,
  }) async {
    try {
      final response = await _dio.put(
        '/teacher/courses/$courseId/modules/$moduleId',
        data: {'title': title},
      );
      return response.data['message'];
    } on DioException catch (e) {
      throw _handleDioError(e, 'Gagal memperbarui modul');
    }
  }

  Future<String> deleteModule({
    required int courseId,
    required int moduleId,
  }) async {
    try {
      // Pastikan sintaks rute menggunakan DUA parameter path: courseId dan moduleId
      final response = await _dio.delete(
        '/teacher/courses/$courseId/modules/$moduleId',
      );
      return response.data['message'];
    } on DioException catch (e) {
      throw _handleDioError(e, 'Gagal menghapus modul');
    }
  }

  // --- LESSON ---
  Future<String> updateLesson({
    required int moduleId,
    required int lessonId,
    required String title,
    required String contentType,
    String? contentBody,
  }) async {
    try {
      final response = await _dio.put(
        '/teacher/modules/$moduleId/lessons/$lessonId',
        data: {
          'title': title,
          'content_type': contentType,
          'content_body': contentBody,
        },
      );
      return response.data['message'];
    } on DioException catch (e) {
      throw _handleDioError(e, 'Gagal memperbarui materi');
    }
  }

  Future<String> deleteLesson({
    required int moduleId,
    required int lessonId,
  }) async {
    try {
      // Perhatikan URL yang harus mencakup moduleId dan lessonId
      final response = await _dio.delete(
        '/teacher/modules/$moduleId/lessons/$lessonId',
      );
      return response.data['message'];
    } on DioException catch (e) {
      throw _handleDioError(e, 'Gagal menghapus materi');
    }
  }

  // --- QUIZ ---
  Future<String> updateQuiz({
    required int courseId,
    required int quizId,
    required String title,
    required String description,
    int? duration,
    int? moduleId,
  }) async {
    try {
      final response = await _dio.put(
        '/teacher/courses/$courseId/quizzes/$quizId',
        data: {
          'title': title,
          'description': description,
          'duration': duration, // <-- MENGIRIM DURATION (null jika kosong)
          'module_id': moduleId, // <-- MENGIRIM MODULE_ID
        },
      );
      return response.data['message'];
    } on DioException catch (e) {
      throw _handleDioError(e, 'Gagal memperbarui kuis');
    }
  }

  Future<String> deleteQuiz({
    required int courseId,
    required int quizId,
  }) async {
    try {
      final response = await _dio.delete(
        '/teacher/courses/$courseId/quizzes/$quizId',
      );
      return response.data['message'];
    } on DioException catch (e) {
      throw _handleDioError(e, 'Gagal menghapus kuis');
    }
  }

  // --- QUESTION ---
  Future<Question> updateQuestion({
    required int quizId,
    required int questionId,
    required String questionText,
    required String questionType,
    required List<Map<String, dynamic>>
    answers, // Format: [{'answer_id': 1 (opsional), 'answer_text': 'Teks', 'is_correct': true/false}]
  }) async {
    try {
      final response = await _dio.put(
        '/teacher/quizzes/$quizId/questions/$questionId',
        data: {
          'question_text': questionText,
          'question_type': questionType,
          'answers': answers,
        },
      );
      // API mengembalikan data pertanyaan yang sudah di-update
      return Question.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e, 'Gagal memperbarui pertanyaan');
    }
  }

  Future<String> deleteQuestion({
    required int quizId,
    required int questionId,
  }) async {
    try {
      // Perhatikan URL yang harus mencakup quizId dan questionId
      final response = await _dio.delete(
        '/teacher/quizzes/$quizId/questions/$questionId',
      );
      return response.data['message'];
    } on DioException catch (e) {
      throw _handleDioError(e, 'Gagal menghapus pertanyaan');
    }
  }

  // --- [BARU] Untuk Dashboard Siswa ---
  Future<StudentDashboard> fetchStudentDashboard() async {
    try {
      final response = await _dio.get('/student/dashboard');
      return StudentDashboard.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e, 'Gagal memuat dashboard.');
    }
  }

  // --- [BARU] Untuk Beranda (Browse) ---
  Future<List<Level>> fetchBrowseData() async {
    try {
      final response = await _dio.get('/browse/courses');
      // API mengembalikan List<Level>, dan setiap Level punya List<Course>
      List<dynamic> data = response.data['data'];
      return data.map((json) => Level.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e, 'Gagal memuat beranda.');
    }
  }

  // --- [BARU] Ambil Kursus berdasarkan Level ---
  Future<List<Course>> fetchCoursesByLevel(int levelId) async {
    try {
      final response = await _dio.get('/courses/level/$levelId');
      List<dynamic> data = response.data['data'];
      // Kita perlu parsing 'level' dan 'subject' yang di-nest
      return data.map((json) => Course.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e, 'Gagal memuat course.');
    }
  }

  // --- [BARU] Ambil Kursus berdasarkan Subject ---
  Future<List<Course>> fetchCoursesBySubject(int subjectId) async {
    try {
      final response = await _dio.get('/courses/subject/$subjectId');
      List<dynamic> data = response.data['data'];
      return data.map((json) => Course.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e, 'Gagal memuat course.');
    }
  }

  // ------------------------------------------------------------------
  // --- ADMIN Operations -------------------------------------------
  // ------------------------------------------------------------------

  // Fitur 1: (Read) Melihat Semua Pengguna
  Future<List<User>> adminGetUsers() async {
    try {
      final response = await _dio.get('/admin/users');
      List<dynamic> data = response.data['data'];
      // Kita gunakan model User yang sudah ada
      return data.map((json) => User.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e, 'Gagal memuat daftar pengguna.');
    }
  }

  // Fitur 2 & 4: (Update) Mengedit Data Pengguna (Role, Nama, Email)
  Future<User> adminUpdateUser({
    required int userId,
    required String fullName,
    required String email,
    required String role,
    int? levelId,
    String? password, // Opsional untuk reset password
  }) async {
    try {
      final response = await _dio.put(
        '/admin/users/$userId',
        data: {
          'full_name': fullName,
          'email': email,
          'role': role,
          'level_id': levelId,
          'password': password, // Akan diabaikan jika null
        },
      );
      return User.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e, 'Gagal memperbarui pengguna.');
    }
  }

  // Fitur 3: (Delete) Menghapus Pengguna
  Future<String> adminDeleteUser(int userId) async {
    try {
      final response = await _dio.delete('/admin/users/$userId');
      return response.data['message'];
    } on DioException catch (e) {
      throw _handleDioError(e, 'Gagal menghapus pengguna.');
    }
  }

  // --- COURSE (ADMIN) ---
  Future<String> adminUpdateCourse({
    required int courseId,
    required String title,
    required String description,
    required int levelId,
    required int subjectId,
  }) async {
    try {
      final response = await _dio.put(
        '/admin/courses/$courseId',
        data: {
          'title': title,
          'description': description,
          'level_id': levelId,
          'subject_id': subjectId,
        },
      );
      return response.data['message'];
    } on DioException catch (e) {
      throw _handleDioError(e, 'Gagal memperbarui kursus (Admin).');
    }
  }

  Future<String> adminDeleteCourse(int courseId) async {
    try {
      final response = await _dio.delete('/admin/courses/$courseId');
      return response.data['message'];
    } on DioException catch (e) {
      throw _handleDioError(e, 'Gagal menghapus kursus (Admin).');
    }
  }

  // --- MODULE (ADMIN) ---
  Future<String> adminUpdateModule({
    required int moduleId,
    required String title,
  }) async {
    try {
      final response = await _dio.put(
        '/admin/modules/$moduleId',
        data: {'title': title},
      );
      return response.data['message'];
    } on DioException catch (e) {
      throw _handleDioError(e, 'Gagal memperbarui modul (Admin).');
    }
  }

  Future<String> adminDeleteModule(int moduleId) async {
    try {
      final response = await _dio.delete('/admin/modules/$moduleId');
      return response.data['message'];
    } on DioException catch (e) {
      throw _handleDioError(e, 'Gagal menghapus modul (Admin).');
    }
  }

  // --- LESSON (ADMIN) ---
  Future<String> adminUpdateLesson({
    required int lessonId,
    required String title,
    required String contentType,
    String? contentBody,
  }) async {
    try {
      final response = await _dio.put(
        '/admin/lessons/$lessonId',
        data: {
          'title': title,
          'content_type': contentType,
          'content_body': contentBody,
        },
      );
      return response.data['message'];
    } on DioException catch (e) {
      throw _handleDioError(e, 'Gagal memperbarui materi (Admin).');
    }
  }

  Future<String> adminDeleteLesson(int lessonId) async {
    try {
      final response = await _dio.delete('/admin/lessons/$lessonId');
      return response.data['message'];
    } on DioException catch (e) {
      throw _handleDioError(e, 'Gagal menghapus materi (Admin).');
    }
  }

  // --- QUIZ (ADMIN) ---
  Future<String> adminUpdateQuiz({
    required int quizId,
    required String title,
    required String description,
    int? duration,
    int? moduleId,
  }) async {
    try {
      final response = await _dio.put(
        '/admin/quizzes/$quizId',
        data: {
          'title': title,
          'description': description,
          'duration': duration,
          'module_id': moduleId,
        },
      );
      return response.data['message'];
    } on DioException catch (e) {
      throw _handleDioError(e, 'Gagal memperbarui kuis (Admin).');
    }
  }

  Future<String> adminDeleteQuiz(int quizId) async {
    try {
      final response = await _dio.delete('/admin/quizzes/$quizId');
      return response.data['message'];
    } on DioException catch (e) {
      throw _handleDioError(e, 'Gagal menghapus kuis (Admin).');
    }
  }

  // --- QUESTION (ADMIN) ---
  Future<String> adminUpdateQuestion({
    required int questionId,
    required String questionText,
    required String questionType,
    required List<Map<String, dynamic>> answers,
  }) async {
    try {
      final response = await _dio.put(
        '/admin/questions/$questionId',
        data: {
          'question_text': questionText,
          'question_type': questionType,
          'answers': answers,
        },
      );
      return response.data['message'];
    } on DioException catch (e) {
      throw _handleDioError(e, 'Gagal memperbarui pertanyaan (Admin).');
    }
  }

  Future<String> adminDeleteQuestion(int questionId) async {
    try {
      final response = await _dio.delete('/admin/questions/$questionId');
      return response.data['message'];
    } on DioException catch (e) {
      throw _handleDioError(e, 'Gagal menghapus pertanyaan (Admin).');
    }
  }

  // --- [BARU] Sempoa Operations ---
  Future<SempoaProgress> fetchSempoaProgress() async {
    try {
      final response = await _dio.get('/sempoa/progress');
      return SempoaProgress.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e, 'Gagal memuat sempoa.');
    }
  }

  Future<String> saveSempoaProgress({
    required int newScore,
    required int newLevel,
    required int newStreak, // <-- TAMBAHKAN INI
  }) async {
    try {
      final response = await _dio.post(
        '/sempoa/progress',
        data: {
          'new_score': newScore,
          'new_level': newLevel,
          'new_streak': newStreak,
        },
      );
      return response.data['message'];
    } on DioException catch (e) {
      throw _handleDioError(e, 'Gagal menyimpan progres Sempoa.');
    }
  }

  // --- [BARU] Fetch Sempoa Leaderboard ---
  Future<List<LeaderboardItem>> fetchSempoaLeaderboard() async {
    try {
      final response = await _dio.get('/sempoa/leaderboard');
      List<dynamic> data = response.data['data'];
      return data.map((json) => LeaderboardItem.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e, 'Gagal memuat sempoa.');
    }
  }

  Future checkAppUpdate(int currentBuild) async {}

  // [BARU] Update Profil Saya (Guru/Siswa)
  Future<User> updateMyProfile({
    required String fullName,
    required String email,
    int? levelId,
  }) async {
    try {
      final response = await _dio.put(
        '/profile/update',
        data: {'full_name': fullName, 'email': email, 'level_id': levelId},
      );
      return User.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e, 'Gagal memperbarui profil.');
    }
  }

  // --- NOTIFICATION API ---
  Future<List<NotificationModel>> fetchNotifications() async {
    try {
      final response = await _dio.get('/notifications');
      List<dynamic> data = response.data['data'];
      return data.map((json) => NotificationModel.fromJson(json)).toList();
    } catch (e) {
      return []; // Return kosong jika gagal
    }
  }

  Future<int> fetchUnreadCount() async {
    try {
      final response = await _dio.get('/notifications/unread-count');
      return response.data['count'] ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<void> markNotificationRead(int id) async {
    await _dio.post('/notifications/$id/read');
  }

  Future<void> markAllRead() async {
    await _dio.post('/notifications/read-all');
  }
}
