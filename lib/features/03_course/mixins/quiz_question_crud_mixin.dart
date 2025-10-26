// lib/features/03_course/mixins/quiz_question_crud_mixin.dart
import 'package:flutter/material.dart';

import '../../../core/models/quiz_model.dart';
import '../../../core/models/question_model.dart';
import '../../../core/services/data_service.dart';

mixin QuizQuestionCrudMixin<T extends StatefulWidget> on State<T> {
  // Kontrak yang harus dipenuhi oleh Screen
  DataService get dataService;
  Future<void> refreshData(); // <--- FUNGSI REFRESH DARI SCREEN
  BuildContext get context;
  bool get mounted;

  // --- [FUNCTION] Edit Kuis ---
  void showEditQuizDialog(Quiz quiz) {
    // Kunci Form harus didefinisikan di sini
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: quiz.title);
    final descriptionController = TextEditingController(text: quiz.description);
    // [PERBAIKAN] Pastikan nilai awal durasi adalah String, meskipun null
    final durationController = TextEditingController(
      text: quiz.duration?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Edit Detail Kuis'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setDialogState) {
              bool isLoading = false;

              Future<void> handleUpdate() async {
                if (!formKey.currentState!.validate()) return;

                setDialogState(() => isLoading = true);
                try {
                  await dataService.updateQuiz(
                    courseId: quiz.courseId, // Ambil dari objek kuis
                    quizId: quiz.quizId,
                    title: titleController.text,
                    description: descriptionController.text,
                    duration: int.tryParse(durationController.text),
                  );

                  if (!mounted) return;
                  Navigator.pop(ctx); // 1. Tutup dialog
                  refreshData(); // 2. PANGGIL REFRESH DATA DI SINI

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Kuis berhasil diperbarui LOL!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  setDialogState(() => isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }

              return SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Judul Kuis',
                        ),
                        validator: (v) =>
                            v!.isEmpty ? 'Judul wajib diisi.' : null,
                      ),
                      TextFormField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Deskripsi',
                        ),
                        maxLines: 3,
                        validator: (v) =>
                            v!.isEmpty ? 'Deskripsi wajib diisi.' : null,
                      ),
                      TextFormField(
                        controller: durationController,
                        decoration: const InputDecoration(
                          labelText: 'Durasi (menit) (Opsional)',
                        ),
                        keyboardType: TextInputType.number,
                      ),

                      Padding(
                        padding: const EdgeInsets.only(top: 24.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Batal'),
                            ),
                            ElevatedButton(
                              onPressed: isLoading ? null : handleUpdate,
                              child: isLoading
                                  ? const CircularProgressIndicator()
                                  : const Text(
                                      'Simpan',
                                      style: TextStyle(color: Colors.white),
                                    ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          actions: const [],
        );
      },
    );
  }

  // --- [FUNCTION] Hapus Kuis ---
  void showDeleteQuizConfirmation(int courseId, Quiz quiz) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Kuis?'),
        content: Text(
          'Anda yakin ingin menghapus kuis "${quiz.title}"? Semua pertanyaan di dalamnya akan hilang.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                final message = await dataService.deleteQuiz(
                  courseId: courseId,
                  quizId: quiz.quizId,
                );

                if (!mounted) return;
                Navigator.pop(ctx); // Tutup dialog
                refreshData(); // Refresh list
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(message),
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
                Navigator.pop(ctx);
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- [FUNCTION] Hapus Pertanyaan ---
  void showDeleteQuestionConfirmation(int quizId, Question question) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Pertanyaan?'),
        content: Text(
          'Anda yakin ingin menghapus pertanyaan nomor ${question.questionId}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                final message = await dataService.deleteQuestion(
                  quizId: quizId,
                  questionId: question.questionId,
                );

                if (!mounted) return;
                Navigator.pop(ctx); // Tutup dialog
                refreshData(); // Refresh list
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(message),
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
                Navigator.pop(ctx);
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
