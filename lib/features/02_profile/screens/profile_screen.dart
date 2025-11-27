// lib/features/02_profile/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/data_service.dart';
import '../../../core/models/level_model.dart';
import '../../00_auth/screens/login_screen.dart';
import 'change_password_screen.dart';
import 'about_app_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _blockingLoading = false;

  // --- FUNGSI 1: Upload Foto (Support Web & Mobile) ---
  Future<void> _pickImage(User user) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );

    if (pickedFile != null) {
      setState(() => _blockingLoading = true);

      try {
        // [PERBAIKAN] Gunakan bytes dan nama file, bukan File path langsung
        final bytes = await pickedFile.readAsBytes();
        final fileName = pickedFile.name;

        await DataService(context).uploadProfilePhoto(bytes, fileName);

        if (!mounted) return;
        
        // [PENTING] Refresh data user agar URL foto baru diambil
        await Provider.of<AuthProvider>(context, listen: false).refreshUser();
        
        // (Opsional) Paksa rebuild widget agar gambar tampil baru
        setState(() {});

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto berhasil diunggah!'), backgroundColor: Colors.green));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      } finally {
        if (mounted) setState(() => _blockingLoading = false);
      }
    }
  }

  // --- FUNGSI 2: Edit Profil (Nama & Email) ---
  void _showEditProfileDialog(User user, List<Level> allLevels) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: user.fullName);
    final emailController = TextEditingController(text: user.email);
    int? selectedLevelId = user.levelId;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Edit Profil'),
          content: StatefulBuilder(
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
                  final auth = Provider.of<AuthProvider>(
                    context,
                    listen: false,
                  );

                  if (auth.user?.role == 'admin') {
                    await DataService(context).adminUpdateUser(
                      userId: user.userId,
                      fullName: nameController.text,
                      email: emailController.text,
                      role: user.role,
                      levelId: selectedLevelId,
                    );
                  } else {
                    throw Exception(
                      'Hubungi Admin untuk mengubah data profil utama.',
                    );
                  }

                  if (!mounted) return;
                  await auth.refreshUser();
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profil diperbarui!'),
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

  // --- FUNGSI 3: Logout ---
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
            onPressed: () async {
              Navigator.of(ctx).pop();
              await Provider.of<AuthProvider>(context, listen: false).logout();

              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
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
    final auth = Provider.of<AuthProvider>(context);
    final User? user = auth.user;

    return FutureBuilder<List<Level>>(
      future: DataService(context).fetchLevels(),
      builder: (context, snapshot) {
        if (!snapshot.hasData &&
            snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allLevels = snapshot.data ?? [];

        if (user == null) {
          return const Center(child: Text('Gagal memuat data pengguna.'));
        }

        return Stack(
          children: [
            ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 24.0,
              ),
              children: [
                // --- Header Foto Profil (Stack) ---
                Center(
                  child: Column(
                    children: [
                      // Gunakan Stack untuk menumpuk icon di atas foto
                      Stack(
                        alignment:
                            Alignment.bottomRight, // Posisi icon di kanan bawah
                        children: [
                          // 1. Foto Profil (Tidak bisa diklik langsung)
                          CircleAvatar(
                            radius: 60, // Perbesar sedikit
                            backgroundColor: Colors.green.shade100,
                            backgroundImage:
                                (user.profilePhotoPath != null &&
                                    user.profilePhotoPath!.isNotEmpty)
                                ? NetworkImage(
                                    'http://192.168.1.3:8000/storage/${user.profilePhotoPath}?v=${DateTime.now().millisecondsSinceEpoch}',
                                  ) // Gunakan 10.0.2.2 untuk emulator
                                : null,
                            child:
                                (user.profilePhotoPath == null ||
                                    user.profilePhotoPath!.isEmpty)
                                ? Text(
                                    user.fullName.isNotEmpty
                                        ? user.fullName[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      fontSize: 48,
                                      color: Colors.green[800],
                                    ),
                                  )
                                : null,
                          ),

                          // 2. Icon Edit (Kamera)
                          Positioned(
                            right: 4,
                            bottom: 4,
                            child: GestureDetector(
                              onTap: () => _pickImage(
                                user,
                              ), // Aksi upload pindah ke sini
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(
                                    255,
                                    4,
                                    31,
                                    184,
                                  ), // Warna biru tema app
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ), // Border putih agar kontras
                                ),
                                child: const Icon(
                                  Icons.camera_alt, // Icon kamera
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
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

                // --- Akun ---
                _buildSectionTitle('Akun'),
                _buildProfileTile(
                  title: 'Edit Profil',
                  icon: Icons.person_outline,
                  onTap: () => _showEditProfileDialog(user, allLevels),
                ),
                _buildProfileTile(
                  title: 'Ganti Password',
                  icon: Icons.lock_outline,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChangePasswordScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // --- Aplikasi ---
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

                // --- Logout ---
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
            ),

            if (_blockingLoading)
              const Positioned.fill(
                child: ColoredBox(
                  color: Colors.black26,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        );
      },
    );
  }

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
