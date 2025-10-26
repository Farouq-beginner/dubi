// lib/features/03_course/mixins/module_crud_mixin.dart
import 'package:flutter/material.dart';

import '../../../core/models/module_model.dart';
import '../../../core/services/data_service.dart';

mixin ModuleCrudMixin<T extends StatefulWidget> on State<T> {
  int get courseId;
  DataService get dataService;
  Future<void> refreshData();
  BuildContext get context;
  bool get mounted;

  // --- [FUNCTION] Tambah Modul ---
  void showAddModuleDialog() {
    final titleController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Buat Modul Baru'),
          content: TextField(
            controller: titleController,
            decoration: const InputDecoration(hintText: 'Judul Modul'),
            autofocus: true,
          ),
          actions: [
            TextButton(child: const Text('Batal'), onPressed: () => Navigator.of(context).pop()),
            ElevatedButton(
              child: const Text('Simpan'),
              onPressed: () async {
                if (titleController.text.isEmpty) return;
                try {
                  await dataService.createModule(
                    courseId: courseId,
                    title: titleController.text,
                  );
                  if (!mounted) return;
                  Navigator.of(context).pop();
                  refreshData(); // Refresh list
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
  }

  // --- [FUNCTION] Hapus Module ---
  void showDeleteModuleConfirmation(Module module) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Modul?'),
        content: Text('Anda yakin ingin menghapus "${module.title}"? Semua materi di dalamnya akan ikut terhapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await dataService.deleteModule(
                  courseId: courseId, 
                  moduleId: module.moduleId
                );
                
                if (!mounted) return;
                Navigator.pop(ctx); // 1. Pop dialog
                refreshData();     // 2. Refresh list

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Modul berhasil dihapus!'), backgroundColor: Colors.green)
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