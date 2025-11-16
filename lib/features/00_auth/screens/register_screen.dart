// screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String _role = 'student'; // Default role
  int? _selectedLevelId; // Untuk menyimpan level ID (TK, SD, dll)
  bool _isLoading = false;
  bool _obscurePassword = true;

  // Data dummy untuk jenjang (nanti bisa diambil dari API)
  final Map<String, int> _levels = {
    'TK': 1,
    'SD': 2,
    'SMP': 3,
    'SMA': 4,
    'UMUM': 5,
  };

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return; // Validasi form

    setState(() => _isLoading = true);

    // Pastikan level diisi jika role-nya student
    if (_role == 'student' && _selectedLevelId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Siswa wajib memilih jenjang (TK/SD/SMP/SMA)'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      String message = await authProvider.register(
        fullName: _nameController.text,
        username: _usernameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        role: _role,
        levelId: _selectedLevelId,
      );

      // Tampilkan pesan sukses
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );

      Navigator.of(context).pop(); // Kembali ke halaman login
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: Text('Daftar Akun Baru'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 4, 31, 184),
                Color.fromARGB(255, 77, 80, 255),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        foregroundColor: Colors.blue[50],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Ayo Bergabung!',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 4, 31, 184),
                    ),
                  ),
                  SizedBox(height: 32),

                  // --- Pilihan Role (Siswa / Guru) ---
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'student',
                        label: Text('Siswa'),
                        icon: Icon(Icons.face),
                      ),
                      ButtonSegment(
                        value: 'teacher',
                        label: Text('Guru'),
                        icon: Icon(Icons.school),
                      ),
                    ],
                    selected: {_role},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        _role = newSelection.first;
                      });
                    },
                    style: SegmentedButton.styleFrom(
                      backgroundColor: Colors.white,
                      selectedBackgroundColor: const Color.fromARGB(
                        255,
                        181,
                        208,
                        255,
                      ),
                    ),
                  ),
                  SizedBox(height: 24),

                  // --- Input Nama Lengkap ---
                  TextFormField(
                    controller: _nameController,
                    decoration: _buildInputDecoration('Nama Lengkap'),
                    validator: (val) =>
                        val!.isEmpty ? 'Nama tidak boleh kosong' : null,
                  ),
                  SizedBox(height: 16),

                  // --- Input Username ---
                  TextFormField(
                    controller: _usernameController,
                    decoration: _buildInputDecoration('Username (unik)'),
                    validator: (val) =>
                        val!.isEmpty ? 'Username tidak boleh kosong' : null,
                  ),
                  SizedBox(height: 16),

                  // --- Input Email ---
                  TextFormField(
                    controller: _emailController,
                    decoration: _buildInputDecoration('Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) => val!.isEmpty || !val.contains('@')
                        ? 'Email tidak valid'
                        : null,
                  ),
                  SizedBox(height: 16),

                  // --- Input Password ---
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration:
                        _buildInputDecoration(
                          'Password (min. 8 karakter)',
                        ).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Color.fromARGB(255, 4, 31, 184),
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                    validator: (val) =>
                        val!.length < 8 ? 'Password minimal 8 karakter' : null,
                  ),
                  SizedBox(height: 16),

                  // --- Pilihan Jenjang (Hanya untuk Siswa) ---
                  if (_role == 'student')
                    DropdownButtonFormField<int>(
                      decoration: _buildInputDecoration('Pilih Jenjang Kamu'),
                      value: _selectedLevelId,
                      hint: Text('Pilih Jenjang'),
                      items: _levels.entries.map((entry) {
                        return DropdownMenuItem<int>(
                          value:
                              entry.value, // value-nya adalah ID (1, 2, 3, 4)
                          child: Text(
                            entry.key,
                          ), // teksnya adalah (TK, SD, ...)
                        );
                      }).toList(),
                      onChanged: (int? newValue) {
                        setState(() {
                          _selectedLevelId = newValue;
                        });
                      },
                      validator: (val) =>
                          val == null ? 'Jenjang wajib diisi' : null,
                    ),

                  SizedBox(height: 32),

                  // --- Tombol Daftar ---
                  if (_isLoading)
                    CircularProgressIndicator()
                  else
                    ElevatedButton(
                      onPressed: _handleRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 4, 31, 184),
                        minimumSize: Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Text(
                        'DAFTAR',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper dekorasi input
  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(
          color: Color.fromARGB(255, 4, 31, 184),
          width: 2,
        ),
      ),
    );
  }
}
