// lib/features/03_course/mixins/course_crud_mixin.dart
import 'package:flutter/material.dart';

import '../../../core/models/course_model.dart';
import '../../../core/models/level_model.dart';
import '../../../core/models/subject_model.dart';
import '../../../core/services/data_service.dart';

// Mixin ini menangani logika Edit dan Delete untuk Course
mixin CourseCrudMixin<T extends StatefulWidget> on State<T> {
  // Kontrak yang harus dipenuhi oleh Screen:
  Course get course; 
  bool get isOwner;
  DataService get dataService;
  Future<void> refreshData(); 
  BuildContext get context;
  bool get mounted;
  
  // --- [FUNCTION] Edit Course Form ---
  void showEditCourseForm() {
    if (!isOwner) return;

    final titleController = TextEditingController(text: course.title);
    final descController = TextEditingController(text: course.description);
    
    // Inisialisasi state lokal untuk dropdown
    int? selectedLevelId = course.level.levelId; 
    int? selectedSubjectId = course.subject.subjectId; 
    
    final levelsFuture = dataService.fetchLevels();
    final subjectsFuture = dataService.fetchSubjects();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Edit Detail Kursus'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setDialogState) { 
              
              bool isLoading = false;
              
              Future<void> handleUpdate() async {
                setDialogState(() => isLoading = true); 
                try {
                  await dataService.updateCourse(
                    courseId: course.courseId,
                    title: titleController.text,
                    description: descController.text,
                    levelId: selectedLevelId!,
                    subjectId: selectedSubjectId!,
                  );
                  
                  if (!mounted) return;
                  Navigator.pop(ctx); 
                  
                  // Pop screen utama agar data di Home Screen ter-refresh
                  Navigator.of(context).pop(true); 
                  
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kursus berhasil diperbarui!'), backgroundColor: Colors.green));
                } catch (e) {
                  setDialogState(() => isLoading = false); 
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
                }
              }

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Judul')),
                    TextField(controller: descController, decoration: const InputDecoration(labelText: 'Deskripsi'), maxLines: 3),
                    const SizedBox(height: 16),
                    
                    FutureBuilder<List<Level>>(
                      future: levelsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) return const CircularProgressIndicator();
                        if (snapshot.hasError) return const Text('Gagal memuat jenjang');
                        return DropdownButtonFormField<int>(
                          value: selectedLevelId,
                          items: snapshot.data!.map((l) => DropdownMenuItem(value: l.levelId, child: Text(l.levelName))).toList(),
                          onChanged: (val) => setDialogState(() => selectedLevelId = val), 
                          decoration: const InputDecoration(labelText: 'Jenjang'),
                        );
                      }
                    ),
                    const SizedBox(height: 16),
                    
                    FutureBuilder<List<Subject>>(
                      future: subjectsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) return const CircularProgressIndicator();
                        if (snapshot.hasError) return const Text('Gagal memuat mapel');
                        return DropdownButtonFormField<int>(
                          value: selectedSubjectId,
                          items: snapshot.data!.map((s) => DropdownMenuItem(value: s.subjectId, child: Text(s.subjectName))).toList(),
                          onChanged: (val) => setDialogState(() => selectedSubjectId = val), 
                          decoration: const InputDecoration(labelText: 'Mata Pelajaran'),
                        );
                      }
                    ),
                    
                    // Action Buttons
                    Padding(
                      padding: const EdgeInsets.only(top: 24.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
                          ElevatedButton(
                            onPressed: isLoading ? null : handleUpdate,
                            child: isLoading ? const CircularProgressIndicator() : const Text('Simpan', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: const [], 
        );
      },
    );
  }

  // --- [FUNCTION] Konfirmasi Hapus Course ---
  void showDeleteConfirmation(BuildContext context) {
    if (!isOwner) return;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Kursus?'),
        content: Text('Anda yakin ingin menghapus "${course.title}"? Ini tidak bisa dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                final message = await dataService.deleteCourse(course.courseId);
                
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.green));
                
                Navigator.of(context).popUntil((route) => route.isFirst); 
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