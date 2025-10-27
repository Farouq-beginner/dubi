// lib/features/01_dashboard/screens/admin_user_management_screen.dart
import 'package:flutter/material.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/data_service.dart';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() => _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  late Future<List<User>> _usersFuture;
  late DataService _dataService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _dataService = DataService(context);
    _refreshUsers();
  }

  Future<void> _refreshUsers() async {
    setState(() {
      _usersFuture = _dataService.adminGetUsers();
    });
  }

  // Fungsi Hapus
  void _deleteUser(User user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hapus Pengguna?'),
        content: Text('Anda yakin ingin menghapus ${user.fullName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await _dataService.adminDeleteUser(user.userId);
                if (!mounted) return;
                Navigator.pop(ctx);
                _refreshUsers();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
              }
            },
            child: Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  // Fungsi Edit (Form Dialog)
  void _editUser(User user) {
    // Controller
    final nameController = TextEditingController(text: user.fullName);
    final emailController = TextEditingController(text: user.email);
    String selectedRole = user.role;
    
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Edit Pengguna'),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: nameController, decoration: InputDecoration(labelText: 'Nama Lengkap')),
                    TextField(controller: emailController, decoration: InputDecoration(labelText: 'Email')),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      items: [
                        DropdownMenuItem(value: 'student', child: Text('Siswa')),
                        DropdownMenuItem(value: 'teacher', child: Text('Guru')),
                      ],
                      onChanged: (val) => setDialogState(() => selectedRole = val!),
                      decoration: InputDecoration(labelText: 'Role'),
                    ),
                  ],
                ),
              );
            }
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _dataService.adminUpdateUser(
                    userId: user.userId,
                    fullName: nameController.text,
                    email: emailController.text,
                    role: selectedRole,
                    levelId: selectedRole == 'student' ? user.levelId : null, // (Level edit bisa ditambahkan)
                  );
                  if (!mounted) return;
                  Navigator.pop(ctx);
                  _refreshUsers();
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
                }
              },
              child: Text('Simpan'),
            ),
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshUsers,
        child: FutureBuilder<List<User>>(
          future: _usersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text(snapshot.error.toString()));
            }
            
            final users = snapshot.data ?? [];

            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                final roleColor = user.role == 'teacher' ? Colors.blue : Colors.green;
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: roleColor.withValues(alpha: 0.2),
                      child: Icon(user.role == 'teacher' ? Icons.school : Icons.person, color: roleColor),
                    ),
                    title: Text(user.fullName, style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(user.email),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: Icon(Icons.edit, color: Colors.grey[600]), onPressed: () => _editUser(user)),
                        IconButton(icon: Icon(Icons.delete, color: Colors.red[400]), onPressed: () => _deleteUser(user)),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
