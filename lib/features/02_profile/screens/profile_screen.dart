// screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/auth_provider.dart';
import '/models/user_model.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Ambil data user dari AuthProvider
    final User? user = Provider.of<AuthProvider>(context).user;

    if (user == null) {
      return Center(child: Text('Gagal memuat data pengguna.'));
    }

    return ListView(
      padding: EdgeInsets.all(24.0),
      children: [
        // --- Kartu Profil Interaktif ---
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Icon(
                  Icons.person_pin_circle,
                  size: 100,
                  color: Colors.green,
                ),
                SizedBox(height: 16),
                Text(
                  user.fullName,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  user.email,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                SizedBox(height: 16),
                Chip(
                  label: Text(
                    user.role.toUpperCase(),
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: Colors.green[700],
                ),
              ],
            ),
          ),
        ),
        
        SizedBox(height: 32),

        // --- Tombol Logout ---
        ElevatedButton.icon(
          icon: Icon(Icons.logout, color: Colors.white),
          label: Text('LOGOUT', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[600],
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () {
            // Tampilkan konfirmasi
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text('Logout'),
                content: Text('Anda yakin ingin keluar?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text('Batal'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () {
                      Navigator.of(ctx).pop(); // Tutup dialog
                      // Panggil fungsi logout
                      Provider.of<AuthProvider>(context, listen: false).logout();
                      // AuthCheckScreen akan otomatis pindah halaman
                    },
                    child: Text('Ya, Logout!', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}