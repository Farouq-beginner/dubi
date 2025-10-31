// screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _blockingLoading = true;

  @override
  void initState() {
    super.initState();
    // Tampilkan efek loading saat pertama kali masuk halaman
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await Provider.of<AuthProvider>(context, listen: false).refreshUser();
      } catch (_) {
        // abaikan error refresh; UI tetap ditampilkan
      } finally {
        if (mounted) setState(() => _blockingLoading = false);
      }
    });
  }

  Future<void> _refresh() async {
    setState(() => _blockingLoading = true);
    try {
      await Provider.of<AuthProvider>(context, listen: false).refreshUser();
    } finally {
      if (mounted) setState(() => _blockingLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ambil data user dari AuthProvider
    final User? user = Provider.of<AuthProvider>(context).user;

    if (user == null) {
      return const Center(child: Text('Gagal memuat data pengguna.'));
    }

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            children: [
          // --- Kartu Profil Interaktif ---
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const Icon(
                    Icons.person_pin_circle,
                    size: 100,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.fullName,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user.email,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  Chip(
                    label: Text(
                      user.role.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: Colors.green[700],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 32),

          // --- Tombol Logout ---
          ElevatedButton.icon(
            icon: const Icon(Icons.logout, color: Colors.white),
            label: const Text('LOGOUT', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              // Tampilkan konfirmasi
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Anda yakin ingin keluar?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Batal'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () {
                        Navigator.of(ctx).pop(); // Tutup dialog
                        // Panggil fungsi logout
                        Provider.of<AuthProvider>(context, listen: false).logout();
                        // AuthCheckScreen akan otomatis pindah halaman
                      },
                      child: const Text('Ya, Logout!', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            },
          ),
            ],
          ),
        ),

        if (_blockingLoading)
          Positioned.fill(
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.deepPurpleAccent),
              ),
            ),
          ),
      ],
    );
  }
}