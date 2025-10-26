// lib/features/03_course/mixins/lesson_crud_mixin.dart
import 'package:flutter/material.dart';

import '../../../core/models/lesson_model.dart';
import '../../../core/models/module_model.dart';
import '../../../core/services/data_service.dart';

mixin LessonCrudMixin<T extends StatefulWidget> on State<T> {
  DataService get dataService;
  Future<void> refreshData();
  BuildContext get context;
  bool get mounted;
  
  // --- [FUNCTION] Tambah Materi (Lesson) ---
  void showAddLessonDialog(Module module) {
    final titleController = TextEditingController();
    final contentBodyController = TextEditingController(); 
    String contentType = 'video'; 

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) { 
            return AlertDialog(
              title: Text('Materi Baru: ${module.title}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: titleController, decoration: const InputDecoration(hintText: 'Judul Materi'), autofocus: true),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: contentType,
                      items: ['video', 'text', 'pdf'].map((type) => DropdownMenuItem(value: type, child: Text(type.toUpperCase()))).toList(),
                      onChanged: (val) => setDialogState(() => contentType = val!),
                      decoration: const InputDecoration(labelText: 'Tipe Konten'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: contentBodyController,
                      decoration: InputDecoration(hintText: contentType == 'video' ? 'URL Video' : 'Isi Teks'),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(child: const Text('Batal'), onPressed: () => Navigator.pop(ctx)),
                ElevatedButton(
                  child: const Text('Simpan'),
                  onPressed: () async {
                    if (titleController.text.isEmpty) return;
                    try {
                      await dataService.createLesson(
                        moduleId: module.moduleId,
                        title: titleController.text,
                        contentType: contentType,
                        contentBody: contentBodyController.text,
                      );
                      if (!mounted) return;
                      Navigator.pop(ctx);
                      refreshData(); 
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- [FUNCTION] Hapus Lesson ---
  void showDeleteLessonConfirmation(int moduleId, Lesson lesson) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Materi?'),
        content: Text('Anda yakin ingin menghapus materi "${lesson.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                // Panggil deleteLesson yang mengembalikan String pesan sukses
                await dataService.deleteLesson(
                  moduleId: moduleId, 
                  lessonId: lesson.lessonId
                );
                
                if (!mounted) return;
                Navigator.pop(ctx); // 1. Pop dialog
                refreshData();     // 2. Refresh list (Mengatasi stuck)

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Materi berhasil dihapus!'), backgroundColor: Colors.green)
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
}