// lib/features/03_course/screens/course_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Model yang diperlukan (core)
import '../../../core/models/course_model.dart';
import '../../../core/models/lesson_model.dart';
import '../../../core/models/module_model.dart';
import '../../../core/models/course_detail_model.dart';
import '../../../core/models/quiz_model.dart';
import '../../../core/services/data_service.dart';
import '../../../core/providers/auth_provider.dart';

// Import Mixins (features/03_course)
import '../mixins/course_crud_mixin.dart';
import '../mixins/module_crud_mixin.dart';
import '../mixins/lesson_crud_mixin.dart';
import '../mixins/quiz_question_crud_mixin.dart';

// Layar tujuan (features)
import '../../05_quiz/screens/create_quiz_screen.dart';
import '../../04_lesson/screens/lesson_view_screen.dart';
import '../../04_lesson/screens/youtube_screen.dart';
import '../../04_lesson/screens/pdf_screen.dart';
import '../../05_quiz/screens/quiz_editor_screen.dart';
import '../../05_quiz/screens/quiz_welcome_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  final Course course;
  const CourseDetailScreen({super.key, required this.course});

  @override
  _CourseDetailScreenState createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen>
    with
        CourseCrudMixin<CourseDetailScreen>,
        ModuleCrudMixin<CourseDetailScreen>,
        LessonCrudMixin<CourseDetailScreen>,
        QuizQuestionCrudMixin<CourseDetailScreen> {
  late Future<CourseDetail> _detailFuture;
  late DataService _dataService;
  late bool _isOwner;
  late bool _isAdmin;

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  // -------------------------------------------------------------
  // --- Implementasi GETTER untuk Memenuhi Kontrak Mixin ---
  // -------------------------------------------------------------
  @override
  Course get course => widget.course;
  @override
  bool get isOwner => _isOwner;
  @override
  BuildContext get context => super.context;
  @override
  bool get mounted => super.mounted;
  @override
  int get courseId => widget.course.courseId;
  @override
  DataService get dataService => _dataService;

  @override
  Future<void> refreshData() => _refreshData();

  // -------------------------------------------------------------
  // --- Logic Internal State ---
  // -------------------------------------------------------------

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _dataService = DataService(context);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    _isOwner =
        (auth.user?.userId == widget.course.createdByUserId) &&
        (auth.user?.role == 'teacher');
    _isAdmin = (auth.user?.role == 'admin');

    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() {
      _detailFuture = _dataService.fetchCourseDetails(widget.course.courseId);
    });
  }

  // --- WIDGET HELPER INLINE UNTUK MENGGANTIKAN FILE TERPISAH ---

  Widget _buildModuleTile(Module module) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(
          module.title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.green[800],
          ),
        ),
        leading: Icon(Icons.folder_special, color: Colors.green, size: 30),
        trailing: _isOwner
            ? PopupMenuButton<String>(
                onSelected: (String result) {
                  if (result == 'edit') {
                    showEditModuleDialog(module); // <-- Mixin Call
                  } else if (result == 'delete') {
                    showDeleteModuleConfirmation(module); // <-- Mixin Call
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: Text('Edit Nama Modul'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Text(
                      'Hapus Modul',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              )
            : _isAdmin
            ? PopupMenuButton<String>(
                onSelected: (String result) {
                  if (result == 'edit') {
                    _showAdminEditModuleDialog(module);
                  } else if (result == 'delete') {
                    _showAdminDeleteModuleConfirmation(module);
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: Text('Edit Modul (Admin)'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Text(
                      'Hapus Modul (Admin)',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              )
            : null,

        initiallyExpanded: false,
        children: [
          if (module.lessons.isEmpty && !_isOwner)
            const ListTile(
              title: Text(
                'Belum ada materi di modul ini.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ),

          // Daftar Materi (Lesson)
          ...module.lessons.map((Lesson lesson) {
            return ListTile(
              title: Text(lesson.title),
              leading: Icon(
                lesson.contentType == 'video'
                    ? Icons.play_circle_fill
                    : (lesson.contentType == 'pdf'
                          ? Icons.picture_as_pdf
                          : Icons.article),
                color: lesson.contentType == 'pdf'
                    ? Colors.red[400]
                    : Colors.grey[600],
              ),
              onTap: () {
                final url = lesson.contentBody ?? '';
                if (lesson.contentType == 'video') {
                  // YouTube links open the YoutubeScreen in-app
                  if (url.contains('youtube.com') || url.contains('youtu.be')) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => YoutubeScreen(videoUrl: url),
                      ),
                    );
                    return;
                  }
                  // For other video links (e.g., direct MP4) fall back to LessonViewScreen which handles native playback
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LessonViewScreen(lesson: lesson),
                    ),
                  );
                  return;
                }

                if (lesson.contentType == 'pdf') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PdfScreen(pdfUrl: url),
                    ),
                  );
                  return;
                }

                // Default: open the lesson view for text or unknown types
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LessonViewScreen(lesson: lesson),
                  ),
                );
              },
              trailing: _isOwner
                  ? PopupMenuButton<String>(
                      onSelected: (String result) {
                        if (result == 'edit') {
                          showEditLessonDialog(
                            module,
                            lesson,
                          ); // <-- PANGGIL FUNGSI INI
                        } else if (result == 'delete') {
                          showDeleteLessonConfirmation(module.moduleId, lesson);
                        }
                      },
                      itemBuilder: (BuildContext context) =>
                          <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'edit',
                              child: Text('Edit Materi'),
                            ),
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: Text(
                                'Hapus Materi',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                    )
                  : _isAdmin
                  ? PopupMenuButton<String>(
                      onSelected: (String result) {
                        if (result == 'edit') {
                          _showAdminEditLessonDialog(lesson);
                        } else if (result == 'delete') {
                          _showAdminDeleteLessonConfirmation(lesson);
                        }
                      },
                      itemBuilder: (BuildContext context) =>
                          <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'edit',
                              child: Text('Edit Materi (Admin)'),
                            ),
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: Text(
                                'Hapus Materi (Admin)',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                    )
                  : null,
            );
          }),

          // Tombol "Tambah Materi"
          if (_isOwner)
            ListTile(
              tileColor: Colors.blue[50],
              leading: Icon(Icons.add_box, color: Colors.blue[700]),
              title: const Text(
                'Tambah Materi Baru',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () => showAddLessonDialog(module), // <-- Mixin Call
            ),
        ],
      ),
    );
  }

  Widget _buildQuizTile(Quiz quiz) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(
          _isOwner ? Icons.edit_document : Icons.quiz,
          color: Colors.deepPurple,
          size: 30,
        ),
        title: Text(
          quiz.title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(quiz.description),
        trailing: _isOwner
            ? PopupMenuButton<String>(
                onSelected: (String result) {
                  if (result == 'edit') {
                    showEditQuizDialog(quiz);
                  } else if (result == 'delete') {
                    // Guru Hapus Milik Sendiri
                    showDeleteQuizConfirmation(widget.course.courseId, quiz);
                  }
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: Text('Edit Kuis'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Text(
                      'Hapus Kuis',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              )
            : (_isAdmin) // <-- Jika bukan pemilik, tapi dia Admin
            ? PopupMenuButton<String>(
                onSelected: (String result) {
                  if (result == 'edit') {
                    _showAdminEditQuizDialog(quiz);
                  } else if (result == 'delete') {
                    _adminDeleteCourseGlobal(quiz.quizId, quiz.title);
                  }
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: Text('Edit Kuis (Admin)'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Text(
                      'Hapus Kuis (Admin)',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              )
            : const Icon(Icons.arrow_forward_ios),
        onTap: () {
          // --- [PERBAIKAN DI SINI] ---
          if (_isOwner) {
            // JIKA GURU: Buka Editor (Ini sudah benar)
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => QuizEditorScreen(
                  quizId: quiz.quizId,
                  quizTitle: quiz.title,
                ),
              ),
            ).then((_) => _refreshData());
          } else {
            // JIKA SISWA: Buka Halaman Welcome (Bukan QuizScreen langsung)
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => QuizWelcomeScreen(
                  // <-- PANGGIL INI
                  quizId: quiz.quizId,
                  quizTitle: quiz.title,
                ),
              ),
            );
          }
        },
      ),
    );
  }

  // --- FUNGSI BARU: Hapus Kuis Global (Admin) ---
  void _adminDeleteCourseGlobal(int quizId, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hapus Kuis Global?'),
        content: Text('Admin: Hapus kuis "${title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await dataService.adminDeleteQuiz(
                  quizId,
                ); // <-- Panggil delete Quiz Admin
                if (!mounted) return;
                Navigator.pop(ctx);
                _refreshData();
              } catch (e) {
                /* ... error handling ... */
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAdminEditQuizDialog(Quiz quiz) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: quiz.title);
    final descController = TextEditingController(text: quiz.description);
    final durationController = TextEditingController(
      text: quiz.duration?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          bool isLoading = false;
          Future<void> handleSave() async {
            if (!formKey.currentState!.validate()) return;
            setDialogState(() => isLoading = true);
            try {
              await dataService.adminUpdateQuiz(
                quizId: quiz.quizId,
                title: titleController.text,
                description: descController.text,
                duration: int.tryParse(durationController.text),
              );
              if (!mounted) return;
              Navigator.pop(ctx);
              _refreshData();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Kuis diperbarui (Admin).'),
                  backgroundColor: Colors.green,
                ),
              );
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
          }

          return AlertDialog(
            title: const Text('Edit Kuis (Admin)'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Judul'),
                      validator: (v) =>
                          v!.isEmpty ? 'Judul wajib diisi.' : null,
                    ),
                    TextFormField(
                      controller: descController,
                      decoration: const InputDecoration(labelText: 'Deskripsi'),
                      maxLines: 3,
                      validator: (v) =>
                          v!.isEmpty ? 'Deskripsi wajib diisi.' : null,
                    ),
                    TextFormField(
                      controller: durationController,
                      decoration: const InputDecoration(
                        labelText: 'Durasi (menit)',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (isLoading) return;
                  await handleSave();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                ),
                child: const Text(
                  'Simpan',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAdminEditModuleDialog(Module module) {
    final titleController = TextEditingController(text: module.title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Modul (Admin)'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(labelText: 'Judul Modul'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await dataService.adminUpdateModule(
                  moduleId: module.moduleId,
                  title: titleController.text,
                );
                if (!mounted) return;
                Navigator.pop(ctx);
                _refreshData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Modul diperbarui (Admin).'),
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
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAdminDeleteModuleConfirmation(Module module) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Modul (Admin)?'),
        content: Text('Hapus modul "${module.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await dataService.adminDeleteModule(module.moduleId);
                if (!mounted) return;
                Navigator.pop(ctx);
                _refreshData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Modul dihapus (Admin).'),
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

  void _showAdminEditLessonDialog(Lesson lesson) {
    final titleController = TextEditingController(text: lesson.title);
    final contentBodyController = TextEditingController(
      text: lesson.contentBody,
    );
    String contentType = lesson.contentType;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          bool isLoading = false;
          return AlertDialog(
            title: const Text('Edit Materi (Admin)'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Judul Materi',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: contentType,
                    items: const [
                      DropdownMenuItem(value: 'video', child: Text('VIDEO')),
                      DropdownMenuItem(value: 'text', child: Text('TEXT')),
                      DropdownMenuItem(value: 'pdf', child: Text('PDF')),
                    ],
                    onChanged: (val) =>
                        setDialogState(() => contentType = val ?? 'text'),
                    decoration: const InputDecoration(labelText: 'Tipe Konten'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: contentBodyController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: contentType == 'video'
                          ? 'URL Video (MP4 langsung)'
                          : (contentType == 'pdf' ? 'URL PDF' : 'Isi Konten'),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (isLoading) return;
                  setDialogState(() => isLoading = true);
                  try {
                    // Validasi: jika video, wajib MP4 langsung dan bukan YouTube/Drive/Vimeo
                    if (contentType == 'video') {
                      final url = contentBodyController.text.trim();
                      final uri = Uri.tryParse(url);
                      final isHttp =
                          uri != null &&
                          (uri.scheme == 'http' || uri.scheme == 'https');
                      final isMp4 =
                          uri != null &&
                          uri.path.toLowerCase().endsWith('.mp4');
                      final host = uri?.host.toLowerCase() ?? '';
                      final forbidden =
                          host.contains('youtube.com') ||
                          host.contains('youtu.be') ||
                          host.contains('vimeo.com') ||
                          host.contains('drive.google.com');
                      if (!isHttp || !isMp4 || forbidden) {
                        if (!mounted) return;
                        setDialogState(() => isLoading = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Gunakan tautan MP4 langsung (bukan YouTube/Drive/Vimeo).',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                    }
                    await dataService.adminUpdateLesson(
                      lessonId: lesson.lessonId,
                      title: titleController.text,
                      contentType: contentType,
                      contentBody: contentBodyController.text,
                    );
                    if (!mounted) return;
                    Navigator.pop(ctx);
                    _refreshData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Materi diperbarui (Admin).'),
                        backgroundColor: Colors.green,
                      ),
                    );
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
                child: const Text(
                  'Simpan',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAdminDeleteLessonConfirmation(Lesson lesson) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Materi (Admin)?'),
        content: Text('Hapus materi "${lesson.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await dataService.adminDeleteLesson(lesson.lessonId);
                if (!mounted) return;
                Navigator.pop(ctx);
                _refreshData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Materi dihapus (Admin).'),
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
  // --- END WIDGET HELPER INLINE ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.course.title, style: TextStyle(color: Colors.white)),
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
        actions: [
          // TOMBOL EDIT (Dipanggil dari Mixin)
          if (_isOwner)
            IconButton(
              icon: const Icon(Icons.edit),
              // PERBAIKAN: Hapus 'context' dan '() =>'
              onPressed: showEditCourseForm,
            ),
          // TOMBOL DELETE (Dipanggil dari Mixin)
          if (_isOwner)
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
              // PERBAIKAN: Hapus 'context' dan '() =>'
              onPressed: showDeleteConfirmation,
            ),
          // ADMIN: Edit & Hapus Course
          if (!_isOwner && _isAdmin)
            IconButton(
              tooltip: 'Edit Kursus (Admin)',
              icon: const Icon(Icons.admin_panel_settings),
              onPressed: _showAdminEditCourseForm,
            ),
          if (!_isOwner && _isAdmin)
            IconButton(
              tooltip: 'Hapus Kursus (Admin)',
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: _showAdminDeleteCourseConfirmation,
            ),
        ],
      ),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _refreshData,
        child: FutureBuilder<CourseDetail>(
          future: _detailFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('${snapshot.error}'));
            }
            if (!snapshot.hasData) {
              return const Center(child: Text('Data tidak ditemukan.'));
            }

            final courseDetail = snapshot.data!;
            final modules = courseDetail.modules;
            final quizzes = courseDetail.quizzes;

            if (modules.isEmpty && quizzes.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    _isOwner
                        ? 'Kursus ini masih kosong. Tekan tombol + untuk menambah modul pertama Anda!'
                        : 'Belum ada materi atau kuis di kursus ini.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ),
              );
            }

            // Gabungkan Modul dan Kuis ke dalam satu list
            List<Widget> contentList = [];

            // 1. Bagian Modul
            if (modules.isNotEmpty) {
              contentList.add(
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    'Materi Belajar',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              );
              contentList.addAll(
                modules.map((module) => _buildModuleTile(module)),
              ); // <-- Panggil helper inline
            }

            // 2. Bagian Kuis
            if (quizzes.isNotEmpty) {
              contentList.add(
                const Padding(
                  padding: EdgeInsets.only(top: 24.0, bottom: 16.0),
                  child: Text(
                    'Uji Pemahaman (Kuis)',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              );
              contentList.addAll(
                quizzes.map((quiz) => _buildQuizTile(quiz)),
              ); // <-- Panggil helper inline
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: contentList,
            );
          },
        ),
      ),

      floatingActionButton: _isOwner
          ? Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton.extended(
                  heroTag: 'fab_modul',
                  onPressed: showAddModuleDialog, // <-- Mixin Call
                  icon: const Icon(Icons.add_box, color: Colors.white),
                  label: const Text(
                    'Tambah Modul',
                    style: TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.green,
                ),
                const SizedBox(height: 16),
                FloatingActionButton.extended(
                  heroTag: 'fab_kuis',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            CreateQuizScreen(courseId: widget.course.courseId),
                      ),
                    ).then((_) => _refreshData());
                  },
                  icon: const Icon(Icons.add_task, color: Colors.white),
                  label: const Text(
                    'Tambah Kuis',
                    style: TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.deepPurple,
                ),
              ],
            )
          : null,
    );
  }

  // =================== ADMIN HANDLERS ===================
  void _showAdminDeleteCourseConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Kursus (Admin)?'),
        content: Text('Anda yakin ingin menghapus "${widget.course.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await dataService.adminDeleteCourse(widget.course.courseId);
                if (!mounted) return;
                Navigator.pop(ctx);
                Navigator.of(context).pop(true);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Kursus dihapus (Admin).'),
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

  void _showAdminEditCourseForm() {
    final titleController = TextEditingController(text: widget.course.title);
    final descController = TextEditingController(
      text: widget.course.description,
    );
    final formKey = GlobalKey<FormState>();

    int? selectedLevelId = widget.course.level?.levelId;
    int? selectedSubjectId = widget.course.subject.subjectId;

    final levelsFuture = dataService.fetchLevels();
    final subjectsFuture = dataService.fetchSubjects();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Edit Kursus (Admin)'),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              bool isLoading = false;

              Future<void> handleSave() async {
                if (formKey.currentState == null ||
                    !formKey.currentState!.validate())
                  return;
                setStateDialog(() => isLoading = true);
                try {
                  await dataService.adminUpdateCourse(
                    courseId: widget.course.courseId,
                    title: titleController.text,
                    description: descController.text,
                    levelId: selectedLevelId!,
                    subjectId: selectedSubjectId!,
                  );
                  if (!mounted) return;
                  Navigator.pop(ctx);
                  _refreshData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Kursus diperbarui (Admin).'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  setStateDialog(() => isLoading = false);
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
                        decoration: const InputDecoration(labelText: 'Judul'),
                        validator: (v) =>
                            v!.isEmpty ? 'Judul wajib diisi.' : null,
                      ),
                      TextFormField(
                        controller: descController,
                        decoration: const InputDecoration(
                          labelText: 'Deskripsi',
                        ),
                        maxLines: 3,
                        validator: (v) =>
                            v!.isEmpty ? 'Deskripsi wajib diisi.' : null,
                      ),
                      const SizedBox(height: 16),
                      FutureBuilder(
                        future: levelsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting)
                            return const CircularProgressIndicator();
                          if (snapshot.hasError || !snapshot.hasData)
                            return const Text('Gagal memuat jenjang');
                          return DropdownButtonFormField<int>(
                            value: selectedLevelId,
                            items: snapshot.data!
                                .map<DropdownMenuItem<int>>(
                                  (l) => DropdownMenuItem(
                                    value: l.levelId,
                                    child: Text(l.levelName),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) =>
                                setStateDialog(() => selectedLevelId = val),
                            decoration: const InputDecoration(
                              labelText: 'Jenjang',
                            ),
                            validator: (v) =>
                                v == null ? 'Jenjang wajib dipilih.' : null,
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      FutureBuilder(
                        future: subjectsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting)
                            return const CircularProgressIndicator();
                          if (snapshot.hasError || !snapshot.hasData)
                            return const Text('Gagal memuat mapel');
                          return DropdownButtonFormField<int>(
                            value: selectedSubjectId,
                            items: snapshot.data!
                                .map<DropdownMenuItem<int>>(
                                  (s) => DropdownMenuItem(
                                    value: s.subjectId,
                                    child: Text(s.subjectName),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) =>
                                setStateDialog(() => selectedSubjectId = val),
                            decoration: const InputDecoration(
                              labelText: 'Mata Pelajaran',
                            ),
                            validator: (v) => v == null
                                ? 'Mata Pelajaran wajib dipilih.'
                                : null,
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Batal'),
                          ),
                          ElevatedButton(
                            onPressed: isLoading ? null : handleSave,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Simpan',
                                    style: TextStyle(color: Colors.white),
                                  ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
