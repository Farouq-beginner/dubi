// lib/features/05_quiz/screens/add_question_screen.dart
import 'package:flutter/material.dart';
import '../../../core/services/data_service.dart';

// Model kecil untuk menampung data Pilihan Jawaban di UI
class AnswerOption {
  TextEditingController controller = TextEditingController();
  bool isCorrect = false;

  AnswerOption({this.isCorrect = false});
}

class AddQuestionScreen extends StatefulWidget {
  final int quizId;
  const AddQuestionScreen({Key? key, required this.quizId}) : super(key: key);

  @override
  _AddQuestionScreenState createState() => _AddQuestionScreenState();
}

class _AddQuestionScreenState extends State<AddQuestionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  bool _isLoading = false;

  // Daftar dinamis untuk Pilihan Jawaban
  List<AnswerOption> _answerOptions = [
    AnswerOption(),
    AnswerOption(),
  ]; // Mulai dengan 2 pilihan

  // Fungsi untuk menambah Pilihan Jawaban baru
  void _addAnswerOption() {
    setState(() {
      _answerOptions.add(AnswerOption());
    });
  }

  // Fungsi untuk menghapus Pilihan Jawaban
  void _removeAnswerOption(int index) {
    setState(() {
      _answerOptions.removeAt(index);
    });
  }

  // Fungsi untuk submit
  Future<void> _submitQuestion() async {
    if (!_formKey.currentState!.validate()) return;

    // Validasi Pilihan Jawaban
    int correctCount = 0;
    List<Map<String, dynamic>> answersPayload = [];

    for (var option in _answerOptions) {
      if (option.controller.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Semua pilihan jawaban harus diisi!'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      if (option.isCorrect) correctCount++;

      answersPayload.add({
        'answer_text': option.controller.text,
        'is_correct': option.isCorrect,
      });
    }

    if (correctCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tandai minimal satu jawaban yang benar!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final dataService = DataService(context);

    try {
      await dataService.createQuestion(
        quizId: widget.quizId,
        questionText: _questionController.text,
        questionType: 'multiple_choice',
        answers: answersPayload,
      );

      if (!mounted) return;
      // Kirim 'true' saat pop untuk menandakan sukses
      Navigator.of(context).pop(true);
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
        title: Text(
          'Tambah Pertanyaan Baru',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
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
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(24),
          children: [
            // --- Pertanyaan ---
            Text(
              'Pertanyaan:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            TextFormField(
              controller: _questionController,
              decoration: _buildInputDecoration('Tulis pertanyaan di sini...'),
              maxLines: 4,
              validator: (val) =>
                  val!.isEmpty ? 'Pertanyaan tidak boleh kosong' : null,
            ),
            SizedBox(height: 24),

            // --- Pilihan Jawaban ---
            Text(
              'Pilihan Jawaban:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),

            ..._buildAnswerFields(),

            // Tombol "Tambah Pilihan"
            TextButton.icon(
              icon: Icon(Icons.add_circle_outline, color: Colors.green),
              label: Text(
                'Tambah Pilihan Jawaban',
                style: TextStyle(color: Colors.green),
              ),
              onPressed: _addAnswerOption,
            ),

            SizedBox(height: 32),

            // Tombol Submit
            ElevatedButton(
              onPressed: _isLoading ? null : _submitQuestion,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'SIMPAN PERTANYAAN',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper untuk Pilihan Jawaban Dinamis
  List<Widget> _buildAnswerFields() {
    return _answerOptions.asMap().entries.map((entry) {
      int idx = entry.key;
      AnswerOption option = entry.value;

      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Row(
          children: [
            // Checkbox "Benar"
            Checkbox(
              value: option.isCorrect,
              onChanged: (bool? val) {
                setState(() {
                  option.isCorrect = val ?? false;
                });
              },
              activeColor: Colors.green,
            ),
            // Input Teks
            Expanded(
              child: TextFormField(
                controller: option.controller,
                decoration: _buildInputDecoration('Pilihan ${idx + 1}'),
              ),
            ),
            // Tombol Hapus
            if (_answerOptions.length > 2) // Hanya tampil jika > 2
              IconButton(
                icon: Icon(Icons.remove_circle, color: Colors.red[300]),
                onPressed: () => _removeAnswerOption(idx),
              )
            else
              SizedBox(width: 48), // Placeholder
          ],
        ),
      );
    }).toList();
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
