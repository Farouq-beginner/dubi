// models/user_model.dart
import 'dart:convert';

class User {
  final int userId;
  final String fullName;
  final String email;
  final String role;
  final int? levelId; 

  User({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.role,
    this.levelId,
  });

  /// Factory constructor: Mengubah JSON (Map) dari API menjadi Objek User
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      // Pastikan semua key di sini BENAR
      userId: json['user_id'],
      fullName: json['full_name'],
      email: json['email'],
      role: json['role'],
      levelId: json['level_id'], 
    );
  }

  /// Method: Mengubah Objek User kembali menjadi JSON (Map)
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'full_name': fullName,
      'email': email,
      'role': role,
      'level_id': levelId,
    };
  }
}