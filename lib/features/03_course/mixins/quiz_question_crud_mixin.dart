// lib/features/05_quiz/mixins/quiz_question_crud_mixin.dart
import 'package:flutter/material.dart';

import '../../../core/models/quiz_model.dart';
import '../../../core/models/question_model.dart';
import '../../../core/services/data_service.dart';

mixin QuizQuestionCrudMixin<T extends StatefulWidget> on State<T> {
  DataService get dataService;
  Future<void> refreshData(); 
  BuildContext get context;
  bool get mounted;
  
  // --- [FUNCTION] Hapus Kuis ---
  void showDeleteQuizConfirmation(int courseId, Quiz quiz) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Kuis?'),
        content: Text('Anda yakin ingin menghapus kuis "${quiz.title}"? Semua pertanyaan di dalamnya akan hilang.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                final message = await dataService.deleteQuiz(courseId: courseId, quizId: quiz.quizId);
                
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.green));
                
                Navigator.pop(ctx); // Tutup dialog
                refreshData();     // Refresh list
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
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
        content: Text('Anda yakin ingin menghapus pertanyaan nomor ${question.questionId}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                // Panggil deleteQuestion
                await dataService.deleteQuestion(quizId: quizId, questionId: question.questionId);
                
                if (!mounted) return;
                Navigator.pop(ctx); // Tutup dialog
                refreshData();     // Refresh list

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pertanyaan berhasil dihapus!'), backgroundColor: Colors.green)
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  // TODO: Tambahkan showEditQuizForm dan showEditQuestionForm di sini
}