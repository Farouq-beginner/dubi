// lib/features/02_profile/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/data_service.dart'; // <--- Import untuk Edit Profil
import '../../../core/models/level_model.dart'; // <--- Import untuk Edit Profil
import 'change_password_screen.dart'; // <-- Import layar Ubah Password
import 'about_app_screen.dart'; // <--- Import untuk AboutAppScreen
import '../../00_auth/screens/login_screen.dart'; // <-- Import layar Login

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _blockingLoading = false; // Tambahkan variabel ini

  // --- Fungsi Edit Profil (Nama & Email) ---
  void _showEditProfileDialog(User user, List<Level> allLevels) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: user.fullName);
    final emailController = TextEditingController(text: user.email);
    // Kita tidak izinkan edit role di sini, hanya nama & email
    // Jika siswa, kita izinkan ganti jenjang
    int? selectedLevelId = user.levelId;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Edit Profil'),
          content: StatefulBuilder(
            // Agar dropdown level bisa update
            builder: (context, setDialogState) {
              return SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Lengkap',
                        ),
                        validator: (val) =>
                            val!.isEmpty ? 'Nama tidak boleh kosong' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                        validator: (val) => val!.isEmpty || !val.contains('@')
                            ? 'Email tidak valid'
                            : null,
                      ),
                      // Hanya tampilkan pilihan jenjang jika dia siswa
                      if (user.role == 'student') ...[
                        const SizedBox(height: 16),
                        DropdownButtonFormField<int>(
                          value: selectedLevelId,
                          hint: const Text('Pilih Jenjang'),
                          items: allLevels
                              .map(
                                (l) => DropdownMenuItem(
                                  value: l.levelId,
                                  child: Text(l.levelName),
                                ),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setDialogState(() => selectedLevelId = val),
                          decoration: const InputDecoration(
                            labelText: 'Jenjang',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                try {
                  // Panggil API Update (kita bisa gunakan API Admin atau buat API khusus user)
                  // Untuk saat ini, kita gunakan API Admin (jika user adalah admin)
                  // atau kita perlu buat API baru di AuthController untuk 'updateProfile'

                  // NOTE: Kita belum buat API untuk 'update profile'
                  // Kita akan panggil 'adminUpdateUser' jika user-nya admin
                  // Ini harus diganti dengan API /profile/update yang lebih aman nanti
                  final auth = Provider.of<AuthProvider>(
                    context,
                    listen: false,
                  );
                  if (auth.user?.role == 'admin') {
                    await DataService(context).adminUpdateUser(
                      userId: user.userId,
                      fullName: nameController.text,
                      email: emailController.text,
                      role: user.role, // Role tidak diubah
                      levelId: selectedLevelId,
                    );
                  } else {
                    // TODO: Panggil API baru /profile/update
                    throw Exception(
                      'Fitur update profil (non-admin) belum terhubung ke API.',
                    );
                  }

                  if (!mounted) return;
                  // Refresh data user di AuthProvider
                  await auth.refreshUser();
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profil berhasil diperbarui!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _refresh() async {
    setState(() => _blockingLoading = true);
    try {
      await Provider.of<AuthProvider>(context, listen: false).refreshUser();
    } finally {
      if (mounted) setState(() => _blockingLoading = false);
    }
  }

  // --- Fungsi Logout ---
  void _showLogoutDialog() {
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
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()), 
                  (route) => false);
            },
            child: const Text(
              'Ya, Logout!',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ambil data user dari AuthProvider
    final auth = Provider.of<AuthProvider>(context);
    final User? user = auth.user;

    // Gunakan FutureBuilder untuk mengambil data Levels (dibutuhkan untuk form Edit)
    return FutureBuilder<List<Level>>(
      future: DataService(context).fetchLevels(), // Ambil data jenjang
      builder: (context, snapshot) {
        if (!snapshot.hasData &&
            snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allLevels =
            snapshot.data ?? []; // Daftar jenjang (meskipun kosong jika error)

        if (user == null) {
          return const Center(child: Text('Gagal memuat data pengguna.'));
        }

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          children: [
            // --- 1. Header Profil ---
            Center(
              child: Column(
                children: [SizedBox(height: 16),
                  Text(
                    user.fullName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: Colors.green[700],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

            // --- 2. Grup Pengaturan Akun ---
            _buildSectionTitle('Akun'),
            _buildProfileTile(
              title: 'Edit Profil',
              icon: Icons.person_outline,
              onTap: () {
                _showEditProfileDialog(user, allLevels);
              },
            ),
            _buildProfileTile(
              title: 'Ganti Password',
              icon: Icons.lock_outline,
              onTap: () {
                // Navigasi ke layar Ubah Password
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
                );
              },
            ),

            const SizedBox(height: 24),

            // --- 3. Grup Pengaturan Aplikasi ---
            _buildSectionTitle('Aplikasi'),
            _buildProfileTile(
              title: 'Notifikasi',
              icon: Icons.notifications_none_outlined,
              onTap: () {},
            ),
            _buildProfileTile(
              title: 'Tentang Aplikasi',
              icon: Icons.info_outline,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AboutAppScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 40),

            // --- 4. Tombol Logout ---
            ElevatedButton.icon(
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text(
                'LOGOUT',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _showLogoutDialog,
            ),
          ],
        );
      },
    );
  }

  // Helper untuk Judul Grup
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  // Helper untuk Tombol/Tile Pengaturan
  Widget _buildProfileTile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.grey[700]),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
