import 'package:flutter/material.dart';
import '../../../core/services/data_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({Key? key}) : super(key: key);

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  // Controller
  final _codeController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  late DataService _dataService;

  // State UI
  bool _isCodeSent = false; // Apakah kode sudah dikirim?
  bool _isLoading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _dataService = DataService(context);
  }

  @override
  void dispose() {
    _codeController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  // --- Logic 1: Kirim Kode ---
  Future<void> _sendCode() async {
    setState(() => _isLoading = true);
    try {
      final message = await _dataService.sendPasswordCode();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );

      // BERHASIL: Pindah ke tampilan verifikasi
      setState(() {
        _isCodeSent = true; // <-- INI YANG AKAN MEMBUKA FORM RESET PASSWORD
      });
    } catch (e) {
      if (!mounted) return;

      // Jika terjadi error (misalnya timeout), tetap tampilkan error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );

      // [PERBAIKAN] Tambahkan opsi untuk pindah manual jika yakin kode sudah terkirim
      if (e.toString().contains('Koneksi lambat')) {
        // Berdasarkan pesan error yang kita buat
        setState(() {
          _isCodeSent = true;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- Logic 2: Simpan Password Baru ---
  Future<void> _submitNewPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final message = await _dataService.resetPasswordWithCode(
        code: _codeController.text,
        newPassword: _passController.text,
        confirmPassword: _confirmPassController.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );

      // Kembali ke halaman profil setelah sukses
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ganti Password',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        elevation: 1,
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: _isCodeSent ? _buildResetForm() : _buildSendCodeView(),
      ),
    );
  }

  // Tampilan 1: Tombol Kirim Kode
  Widget _buildSendCodeView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.mark_email_read_outlined,
          size: 80,
          color: Colors.blueAccent,
        ),
        const SizedBox(height: 24),
        const Text(
          'Demi keamanan, kami perlu memverifikasi email Anda.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 8),
        const Text(
          'Tekan tombol di bawah untuk menerima Kode Verifikasi.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _sendCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'Kirim Kode Verifikasi',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
          ),
        ),
      ],
    );
  }

  // Tampilan 2: Form Input Kode & Password
  Widget _buildResetForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kode Verifikasi telah dikirim ke email Anda.',
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // 1. Input Kode
          TextFormField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Kode Verifikasi (6 Digit)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.vpn_key),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Kode wajib diisi';
              if (value.length < 6) return 'Kode harus 6 digit';
              return null;
            },
          ),
          const SizedBox(height: 24),

          // 2. Password Baru
          TextFormField(
            controller: _passController,
            obscureText: _obscurePass,
            decoration: InputDecoration(
              labelText: 'Password Baru',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePass ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () => setState(() => _obscurePass = !_obscurePass),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Password wajib diisi';
              if (value.length < 8) return 'Minimal 8 karakter';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // 3. Konfirmasi Password
          TextFormField(
            controller: _confirmPassController,
            obscureText: _obscureConfirm,
            decoration: InputDecoration(
              labelText: 'Ulangi Password Baru',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty)
                return 'Konfirmasi password wajib diisi';
              if (value != _passController.text) return 'Password tidak sama';
              return null;
            },
          ),

          const SizedBox(height: 32),

          // Tombol Simpan
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitNewPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Simpan Password Baru',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
