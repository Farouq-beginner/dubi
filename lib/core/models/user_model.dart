// models/user_model.dart

class User {
  final int userId;
  final String fullName;
  final String username;
  final String email;
  final String role;
  final int? levelId;
  final String? profilePhotoPath; // Tambahkan properti ini


  User({
    required this.userId,
    required this.fullName,
    required this.username,
    required this.email,
    required this.role,
    this.levelId,
    this.profilePhotoPath,
  });

  /// Factory constructor: Mengubah JSON (Map) dari API menjadi Objek User
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      // Pastikan semua key di sini BENAR
      userId: json['user_id'],
      fullName: json['full_name'],
      username: json['username'],
      email: json['email'],
      role: json['role'],
      levelId: json['level_id'],
      profilePhotoPath: json['profile_photo_path'],
    );
  }

  /// Method: Mengubah Objek User kembali menjadi JSON (Map)
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'full_name': fullName,
      'username': username,
      'email': email,
      'role': role,
      'level_id': levelId,
      'profile_photo_path': profilePhotoPath,
    };
  }
}