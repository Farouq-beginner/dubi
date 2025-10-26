// lib/features/05_quiz/screens/edit_question_screen.dart
import 'package:flutter/material.dart';
import '../../../core/services/data_service.dart';
import '../../../core/models/question_model.dart';

// Model helper yang sama dengan add_question_screen.dart
class AnswerOption {
  TextEditingController controller; // <-- 1. Jangan inisialisasi di sini
  bool isCorrect;
  int? answerId;

  // 2. Inisialisasi controller di dalam constructor
  AnswerOption({String text = '', this.isCorrect = false, this.answerId})
      : controller = TextEditingController(text: text); // <-- 3. Set text di sini
}

class EditQuestionScreen extends StatefulWidget {
  final int quizId;
  final Question question; // Kita terima data pertanyaan yang akan diedit
  const EditQuestionScreen({Key? key, required this.quizId, required this.question}) : super(key: key);

  @override
  _EditQuestionScreenState createState() => _EditQuestionScreenState();
}

class _EditQuestionScreenState extends State<EditQuestionScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _questionController;
  bool _isLoading = false;
  List<AnswerOption> _answerOptions = [];

  @override
  void initState() {
    super.initState();
    // Isi form dengan data yang ada
    _questionController = TextEditingController(text: widget.question.questionText);
// --- [PERBAIKI BLOK INI] ---
    _answerOptions = widget.question.answers.map((answer) {
      return AnswerOption(
        text: answer.answerText, // <-- Sekarang ini akan mengisi teks
        isCorrect: answer.isCorrect ?? false, // <-- Ambil 'isCorrect' dari API Guru
        answerId: answer.answerId,
      );
    }).toList();
  }

  void _addAnswerOption() {
    setState(() {
      _answerOptions.add(AnswerOption()); // Menambah jawaban baru (tanpa answerId)
    });
  }

  void _removeAnswerOption(int index) {
    setState(() {
      _answerOptions.removeAt(index);
    });
  }

  Future<void> _submitQuestion() async {
    if (!_formKey.currentState!.validate()) return;
    
    int correctCount = 0;
    List<Map<String, dynamic>> answersPayload = [];
    
    for (var option in _answerOptions) {
      if (option.controller.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Semua pilihan jawaban harus diisi!'), backgroundColor: Colors.orange));
        return;
      }
      if (option.isCorrect) correctCount++;
      
      answersPayload.add({
        'answer_id': option.answerId, // Kirim ID jika ada (untuk update)
        'answer_text': option.controller.text,
        'is_correct': option.isCorrect,
      });
    }

    if (correctCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tandai minimal satu jawaban yang benar!'), backgroundColor: Colors.orange));
      return;
    }

    setState(() => _isLoading = true);
    final dataService = DataService(context);

    try {
      await dataService.updateQuestion(
        quizId: widget.quizId,
        questionId: widget.question.questionId,
        questionText: _questionController.text,
        questionType: 'multiple_choice',
        answers: answersPayload,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true); // Kirim 'true' tanda sukses

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
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
        title: Text('Edit Pertanyaan'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(24),
          children: [
            // --- Pertanyaan ---
            Text('Pertanyaan:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            TextFormField(
              controller: _questionController,
              decoration: _buildInputDecoration('Tulis pertanyaan di sini...'),
              maxLines: 4,
              validator: (val) => val!.isEmpty ? 'Pertanyaan tidak boleh kosong' : null,
            ),
            SizedBox(height: 24),

            // --- Pilihan Jawaban ---
            Text('Pilihan Jawaban:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            
            ..._buildAnswerFields(),
            
            TextButton.icon(
              icon: Icon(Icons.add_circle_outline, color: Colors.green),
              label: Text('Tambah Pilihan Jawaban', style: TextStyle(color: Colors.green)),
              onPressed: _addAnswerOption,
            ),
            
            SizedBox(height: 32),

            ElevatedButton(
              onPressed: _isLoading ? null : _submitQuestion,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('SIMPAN PERUBAHAN', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAnswerFields() {
    return _answerOptions.asMap().entries.map((entry) {
      int idx = entry.key;
      AnswerOption option = entry.value;

      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Row(
          children: [
            Checkbox(
              value: option.isCorrect,
              onChanged: (bool? val) {
                setState(() {
                  option.isCorrect = val ?? false;
                });
              },
              activeColor: Colors.green,
            ),
            Expanded(
              child: TextFormField(
                controller: option.controller,
                decoration: _buildInputDecoration('Pilihan ${idx + 1}'),
              ),
            ),
            IconButton(
              icon: Icon(Icons.remove_circle, color: Colors.red[300]),
              onPressed: () => _removeAnswerOption(idx),
            )
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