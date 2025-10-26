// lib/features/05_quiz/screens/create_quiz_screen.dart
import 'package:flutter/material.dart';
import '../../../core/services/data_service.dart';

class CreateQuizScreen extends StatefulWidget {
  final int courseId; // Kita butuh ID kursus tujuannya
  const CreateQuizScreen({Key? key, required this.courseId}) : super(key: key);

  @override
  _CreateQuizScreenState createState() => _CreateQuizScreenState();
}

class _CreateQuizScreenState extends State<CreateQuizScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final dataService = DataService(context);

    try {
      await dataService.createQuiz(
        courseId: widget.courseId,
        title: _titleController.text,
        description: _descriptionController.text,
        duration: int.tryParse(_durationController.text),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kuis baru berhasil dibuat!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(); // Kembali ke detail kursus
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Buat Kuis Baru'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: _buildInputDecoration('Judul Kuis'),
                validator: (val) =>
                    val!.isEmpty ? 'Judul tidak boleh kosong' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _durationController, // <-- Ikat controller
                decoration: _buildInputDecoration('Durasi (dalam menit)'),
                keyboardType: TextInputType.number,
                // Validator opsional
                validator: (val) {
                  if (val == null || val.isEmpty) return null; // Boleh kosong
                  if (int.tryParse(val) == null) return 'Harus berupa angka';
                  return null;
                },
              ),
              SizedBox(height: 32),
              SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: _buildInputDecoration('Deskripsi Kuis'),
                maxLines: 4,
                validator: (val) =>
                    val!.isEmpty ? 'Deskripsi tidak boleh kosong' : null,
              ),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'SIMPAN KUIS',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      filled: true,
      fillColor: Colors.grey[50],
    );
  }
}
