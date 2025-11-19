// lib/features/02_profile/screens/change_password_screen.dart
import 'package:flutter/material.dart';
import '../../../core/services/data_service.dart';

// Enum untuk mengelola langkah-langkah dalam flow
enum PasswordFlowStep { sendCode, verifyCode, setNewPassword }

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  PasswordFlowStep _currentStep = PasswordFlowStep.sendCode;
  late DataService _dataService;
  
  // Controllers
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _showPassword = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _dataService = DataService(context);
  }

  // --- Logic Step 1: Kirim Kode ---
  Future<void> _sendCode() async {
    setState(() => _isLoading = true);
    try {
      final message = await _dataService.sendPasswordCode();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.green));
      setState(() => _currentStep = PasswordFlowStep.verifyCode);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- Logic Step 2: Verifikasi Kode ---
  void _verifyCode() {
    // Di sini kita hanya berpindah ke langkah 3 jika kode diisi (asumsi kode benar)
    // Validasi kode akan dilakukan di langkah 3 oleh backend
    if (_codeController.text.length == 6) {
      setState(() => _currentStep = PasswordFlowStep.setNewPassword);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kode harus 6 digit.'), backgroundColor: Colors.orange));
    }
  }

  // --- Logic Step 3: Reset Password ---
  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    try {
      final message = await _dataService.resetPasswordWithCode(
        code: _codeController.text,
        newPassword: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.green));
      Navigator.of(context).pop(); // Kembali ke Profile Screen
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    String title;

    switch (_currentStep) {
      case PasswordFlowStep.sendCode:
        title = 'Kirim Kode Verifikasi';
        content = _buildSendCodeStep();
        break;
      case PasswordFlowStep.verifyCode:
        title = 'Masukkan Kode (Langkah 2/3)';
        content = _buildVerifyCodeStep();
        break;
      case PasswordFlowStep.setNewPassword:
        title = 'Buat Password Baru (Langkah 3/3)';
        content = _buildSetNewPasswordStep();
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.deepPurple,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: content,
        ),
      ),
    );
  }
  
  // --- UI Step 1: Kirim Kode ---
  Widget _buildSendCodeStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Kami akan mengirim kode verifikasi ke email Anda yang terdaftar.', textAlign: TextAlign.center),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _sendCode,
          icon: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.email_outlined),
          label: Text(_isLoading ? 'Mengirim...' : 'Kirim Kode', style: const TextStyle(fontSize: 16)),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
        ),
      ],
    );
  }

  // --- UI Step 2: Verifikasi Kode ---
  Widget _buildVerifyCodeStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Cek kotak masuk Anda. Masukkan 6 digit kode yang kami kirimkan.', textAlign: TextAlign.center),
        const SizedBox(height: 32),
        TextField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(
            labelText: 'Kode Verifikasi',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _codeController.text.length == 6 ? _verifyCode : null,
          child: const Text('Verifikasi'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
        ),
      ],
    );
  }

  // --- UI Step 3: Set Password Baru ---
  Widget _buildSetNewPasswordStep() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _passwordController,
            obscureText: !_showPassword, // Sembunyikan teks
            decoration: InputDecoration(
              labelText: 'Password Baru (min. 8)',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off),
                onPressed: () {
                  setState(() => _showPassword = !_showPassword);
                },
              ),
            ),
            validator: (val) {
              if (val == null || val.length < 8) return 'Password minimal 8 karakter';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: !_showPassword,
            decoration: const InputDecoration(
              labelText: 'Konfirmasi Password Baru',
              border: OutlineInputBorder(),
            ),
            validator: (val) {
              if (val != _passwordController.text) return 'Konfirmasi password tidak cocok';
              return null;
            },
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _isLoading ? null : _resetPassword,
            child: Text(_isLoading ? 'Mengubah...' : 'Ubah Password', style: const TextStyle(fontSize: 16)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
          ),
        ],
      ),
    );
  }
}