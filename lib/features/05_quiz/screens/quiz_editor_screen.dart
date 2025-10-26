// lib/features/05_quiz/screens/quiz_editor_screen.dart
import 'package:flutter/material.dart';
import '../../../core/models/quiz_model.dart';
import '../../../core/models/question_model.dart';
import '../../../core/services/data_service.dart';
import 'add_question_screen.dart'; // Halaman Form Tambah Pertanyaan

class QuizEditorScreen extends StatefulWidget {
  final int quizId;
  final String quizTitle;
  const QuizEditorScreen({Key? key, required this.quizId, required this.quizTitle}) : super(key: key);

  @override
  _QuizEditorScreenState createState() => _QuizEditorScreenState();
}

class _QuizEditorScreenState extends State<QuizEditorScreen> {
  late Future<Quiz> _quizFuture;
  late DataService _dataService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _dataService = DataService(context);
    _refreshQuiz(); // Panggil data saat pertama kali dimuat
  }

  // Fungsi untuk refresh data kuis
  void _refreshQuiz() {
    setState(() {
      _quizFuture = _dataService.fetchQuizDetails(widget.quizId);
    });
  }
  
  // Fungsi untuk konfirmasi dan hapus pertanyaan
  void _showDeleteConfirmation(Question question) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Pertanyaan?'),
        content: Text('Anda yakin ingin menghapus pertanyaan:\n"${question.questionText}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await _dataService.deleteQuestion(
                  quizId: widget.quizId,
                  questionId: question.questionId,
                );
                if (!mounted) return;
                Navigator.pop(ctx);
                _refreshQuiz(); // Refresh list setelah hapus
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Kuis: ${widget.quizTitle}'),
        backgroundColor: Colors.deepPurple,
      ),
      body: FutureBuilder<Quiz>(
        future: _quizFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error memuat kuis: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.questions == null || snapshot.data!.questions!.isEmpty) {
            return Center(
              child: Text(
                'Kuis ini belum memiliki pertanyaan.\nTekan tombol + untuk menambahkannya.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
            );
          }

          final questions = snapshot.data!.questions!;

          // Tampilkan daftar pertanyaan yang ada
          return RefreshIndicator(
            onRefresh: () async { _refreshQuiz(); },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: questions.length,
              itemBuilder: (context, index) {
                final question = questions[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.deepPurple[100],
                      child: Text('${index + 1}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                    ),
                    title: Text(question.questionText),
                    subtitle: Text('(${question.answers.length} pilihan jawaban)'),
                    trailing: PopupMenuButton<String>(
                      onSelected: (String result) {
                        if (result == 'delete') {
                          _showDeleteConfirmation(question);
                        } else if (result == 'edit') {
                          // TODO: Implementasi Edit Pertanyaan
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fitur Edit belum diimplementasikan!')));
                        }
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'edit',
                          child: Text('Edit Pertanyaan'),
                        ),
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Text('Hapus Pertanyaan', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                    onTap: () {
                      // Navigasi ke Halaman Edit/Preview Pertanyaan
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preview/Edit Pertanyaan...')));
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Buka Halaman Form "Tambah Pertanyaan"
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddQuestionScreen(quizId: widget.quizId),
            ),
          ).then((isSuccess) {
            // Jika 'isSuccess' adalah true (dari pop), refresh list
            if (isSuccess == true) {
              _refreshQuiz();
            }
          });
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah Pertanyaan', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
      ),
    );
  }
}