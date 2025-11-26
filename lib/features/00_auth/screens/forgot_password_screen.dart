// lib/features/00_auth/screens/forgot_password_screen.dart
import 'package:flutter/material.dart';
import '../../../core/services/data_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isCodeSent = false; // Tahap 1 vs Tahap 2
  bool _isLoading = false;
  bool _obscurePass = true;

  // Tahap 1: Kirim Email
  Future<void> _sendCode() async {
    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Masukkan email yang valid')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final msg = await DataService(context).forgotPasswordSendCode(_emailController.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
      setState(() => _isCodeSent = true); // Pindah ke tahap input kode
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Tahap 2: Reset Password
  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final msg = await DataService(context).forgotPasswordReset(
        email: _emailController.text,
        code: _codeController.text,
        newPassword: _passController.text,
        confirmPassword: _confirmController.text,
      );
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
      
      Navigator.pop(context); // Kembali ke Login
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lupa Password'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: _isCodeSent ? _buildResetForm() : _buildEmailForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailForm() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.lock_reset, size: 80, color: Colors.green),
        const SizedBox(height: 24),
        const Text(
          'Masukkan email Anda untuk menerima kode verifikasi.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.email),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _sendCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Kirim Kode', style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ),
      ],
    );
  }

  Widget _buildResetForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          const Text('Kode terkirim! Masukkan kode dan password baru.', textAlign: TextAlign.center),
          const SizedBox(height: 24),
          // Input Email (Read Only)
          TextField(
            controller: _emailController,
            readOnly: true,
            decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder(), filled: true),
          ),
          const SizedBox(height: 16),
          // Input Kode
          TextFormField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Kode Verifikasi', border: OutlineInputBorder()),
            validator: (v) => v!.length < 6 ? 'Kode harus 6 digit' : null,
          ),
          const SizedBox(height: 16),
          // Password Baru
          TextFormField(
            controller: _passController,
            obscureText: _obscurePass,
            decoration: InputDecoration(
              labelText: 'Password Baru',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscurePass ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscurePass = !_obscurePass),
              ),
            ),
            validator: (v) => v!.length < 8 ? 'Min 8 karakter' : null,
          ),
          const SizedBox(height: 16),
          // Konfirmasi
          TextFormField(
            controller: _confirmController,
            obscureText: _obscurePass,
            decoration: const InputDecoration(labelText: 'Konfirmasi Password', border: OutlineInputBorder()),
            validator: (v) => v != _passController.text ? 'Password tidak sama' : null,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _resetPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Reset Password', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}