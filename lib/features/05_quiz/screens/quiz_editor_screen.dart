// lib/features/05_quiz/screens/quiz_editor_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/quiz_model.dart';
import '../../../core/services/data_service.dart';
import '../../../core/providers/auth_provider.dart'; // Untuk cek role admin
import '../../03_course/mixins/quiz_question_crud_mixin.dart'; // Mixin CRUD untuk pertanyaan kuis

import 'add_question_screen.dart'; // Form tambah pertanyaan
import 'edit_question_screen.dart';

class QuizEditorScreen extends StatefulWidget {
  final int quizId;
  final String quizTitle;
  const QuizEditorScreen({
    super.key,
    required this.quizId,
    required this.quizTitle,
  });

  @override
  _QuizEditorScreenState createState() => _QuizEditorScreenState();
}

class _QuizEditorScreenState extends State<QuizEditorScreen>
    with
        QuizQuestionCrudMixin<QuizEditorScreen> // Gunakan Mixin CRUD
        {
  late Future<Quiz> _quizFuture;
  late DataService _dataService;

  // --- Implementasi GETTER untuk Mixin ---
  @override
  DataService get dataService => _dataService;
  @override
  Future<void> refreshData() async {
    _refreshQuiz();
  }

  @override
  BuildContext get context => super.context;
  @override
  bool get mounted => super.mounted;
  // ----------------------------------------

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _dataService = DataService(context);
    _refreshQuiz();
  }

  // Fungsi untuk refresh data kuis
  void _refreshQuiz() {
    setState(() {
      // Panggil API Guru untuk mendapatkan data lengkap (termasuk jawaban benar)
      _quizFuture = _dataService.fetchQuizDetailsForTeacher(widget.quizId);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Ambil role user di sini
    final userRole =
        Provider.of<AuthProvider>(context, listen: false).user?.role ??
        'student';
    final bool isAdmin = userRole == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Kuis: ${widget.quizTitle}',
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
      body: FutureBuilder<Quiz>(
        future: _quizFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error memuat kuis: ${snapshot.error}'));
          }
          if (!snapshot.hasData ||
              snapshot.data!.questions == null ||
              snapshot.data!.questions!.isEmpty) {
            return Center(
              child: Text(
                'Kuis ini belum memiliki pertanyaan.\nTekan tombol + untuk menambahkannya.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
            );
          }

          final quiz = snapshot.data!;
          final questions = quiz.questions!;

          // Tampilkan daftar pertanyaan yang ada
          return RefreshIndicator(
            onRefresh: () async {
              _refreshQuiz();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: questions.length,
              itemBuilder: (context, index) {
                final question = questions[index];

                // Hitung jumlah jawaban benar
                final correctAnswers = question.answers
                    .where((a) => a.isCorrect == true)
                    .length;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.deepPurple[100],
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ),
                    title: Text(question.questionText),
                    subtitle: Text(
                      'Jawaban Benar: $correctAnswers dari ${question.answers.length}',
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (String result) {
                        if (result == 'edit') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditQuestionScreen(
                                quizId: widget.quizId,
                                question: question,
                              ),
                            ),
                          ).then((isSuccess) {
                            if (isSuccess == true) {
                              _refreshQuiz();
                            }
                          });
                        } else if (result == 'delete') {
                          if (isAdmin) {
                            _showAdminDeleteQuestionConfirmation(
                              question.questionId,
                            );
                          } else {
                            // Guru
                            showDeleteQuestionConfirmation(
                              widget.quizId,
                              question,
                            );
                          }
                        }
                      },
                      itemBuilder: (BuildContext context) =>
                          <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'edit',
                              child: Text('Edit Pertanyaan'),
                            ),
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: Text(
                                'Hapus Pertanyaan',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                    ),
                    onTap: () {
                      // Navigasi ke Halaman Edit/Preview Pertanyaan
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Preview/Edit Pertanyaan...'),
                        ),
                      );
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
        label: const Text(
          'Tambah Pertanyaan',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple,
      ),
    );
  }
}

extension on _QuizEditorScreenState {
  void _showAdminDeleteQuestionConfirmation(int questionId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Pertanyaan (Admin)?'),
        content: const Text('Aksi ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await dataService.adminDeleteQuestion(questionId);
                if (!mounted) return;
                Navigator.pop(ctx);
                _refreshQuiz();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Pertanyaan dihapus (Admin).'),
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
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
