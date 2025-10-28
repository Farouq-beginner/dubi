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
            // Tentukan hint text secara dinamis
            String hintText;
            switch (contentType) {
              case 'video':
                hintText = 'URL Video (MP4 langsung)';
                break;
              case 'pdf':
                hintText = 'URL PDF (Link ke file PDF)';
                break;
              case 'text':
              default:
                hintText = 'Isi Teks Materi';
                break;
            }
            return AlertDialog(
              title: Text('Materi Baru: ${module.title}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        hintText: 'Judul Materi',
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: contentType,
                      items: ['video', 'text', 'pdf']
                          .map(
                            (type) => DropdownMenuItem<String>(
                              value: type,
                              child: Text(type.toUpperCase()),
                            ),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setDialogState(() => contentType = val!),
                      decoration: const InputDecoration(
                        labelText: 'Tipe Konten',
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Teks Area yang Dinamis
                    TextFormField(
                      controller: contentBodyController,
                      decoration: InputDecoration(
                        hintText: hintText,
                        labelText: contentType == 'text'
                            ? 'Isi Materi'
                            : (contentType == 'video'
                                ? 'URL Video (MP4 langsung)'
                                : 'Link Konten'),
                      ),
                      maxLines: contentType == 'text' ? 5 : 1,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Batal'),
                  onPressed: () => Navigator.pop(ctx),
                ),
                ElevatedButton(
                  child: const Text('Simpan'),
                  onPressed: () async {
                    if (titleController.text.isEmpty) return;
                    // Validasi: jika video, wajib MP4 langsung dan bukan YouTube/Drive/Vimeo
                    if (contentType == 'video') {
                      final url = contentBodyController.text.trim();
                      if (!_isDirectMp4Url(url)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Gunakan URL video MP4 langsung (contoh: https://.../video.mp4).'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      if (_isForbiddenVideoHost(url)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('URL YouTube/Drive/Vimeo tidak didukung. Harap unggah dan gunakan tautan file MP4 langsung.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                    }
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(e.toString()),
                          backgroundColor: Colors.red,
                        ),
                      );
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
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await dataService.deleteLesson(
                  moduleId: moduleId,
                  lessonId: lesson.lessonId,
                );

                if (!mounted) return;
                Navigator.pop(ctx);
                refreshData();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Materi berhasil dihapus!'),
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

  // --- [BARU] FUNGSI UNTUK EDIT MATERI ---
  void showEditLessonDialog(Module module, Lesson lesson) {
    final titleController = TextEditingController(text: lesson.title);
    final contentBodyController = TextEditingController(
      text: lesson.contentBody,
    );
    String contentType = lesson.contentType;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: Text('Edit Materi: ${lesson.title}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        hintText: 'Judul Materi',
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: contentType,
                      items: ['video', 'text', 'pdf']
                          .map(
                            (type) => DropdownMenuItem<String>(
                              value: type,
                              child: Text(type.toUpperCase()),
                            ),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setDialogState(() => contentType = val!),
                      decoration: const InputDecoration(
                        labelText: 'Tipe Konten',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: contentBodyController,
                      decoration: InputDecoration(
                        hintText: contentType == 'video'
                            ? 'URL Video (MP4 langsung)'
                            : 'Isi Teks',
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Batal'),
                  onPressed: () => Navigator.pop(ctx),
                ),
                ElevatedButton(
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : const Text('Simpan'),
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (titleController.text.isEmpty) return;

                          // Validasi: jika video, wajib MP4 langsung dan bukan YouTube/Drive/Vimeo
                          if (contentType == 'video') {
                            final url = contentBodyController.text.trim();
                            if (!_isDirectMp4Url(url)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Gunakan URL video MP4 langsung (contoh: https://.../video.mp4).'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            if (_isForbiddenVideoHost(url)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('URL YouTube/Drive/Vimeo tidak didukung. Harap unggah dan gunakan tautan file MP4 langsung.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                          }

                          setDialogState(() => isLoading = true);
                          try {
                            await dataService.updateLesson(
                              moduleId: module.moduleId,
                              lessonId: lesson.lessonId,
                              title: titleController.text,
                              contentType: contentType,
                              contentBody: contentBodyController.text,
                            );
                            if (!mounted) return;
                            Navigator.pop(ctx);
                            refreshData();
                          } catch (e) {
                            if (!mounted) return;
                            setDialogState(() => isLoading = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(e.toString()),
                                backgroundColor: Colors.red,
                              ),
                            );
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

  // --- Helper Validasi URL Video ---
  bool _isDirectMp4Url(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) return false;
    final path = uri.path.toLowerCase();
    return path.endsWith('.mp4');
  }

  bool _isForbiddenVideoHost(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    final host = uri.host.toLowerCase();
    return host.contains('youtube.com') ||
        host.contains('youtu.be') ||
        host.contains('vimeo.com') ||
        host.contains('drive.google.com');
  }
}
