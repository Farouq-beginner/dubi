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
import '../../05_quiz/screens/quiz_screen.dart';
import '../../04_lesson/screens/lesson_view_screen.dart';
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
                    : Icons.article,
                color: Colors.grey[600],
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LessonViewScreen(lesson: lesson),
                ),
              ),
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
                  : null,
            );
          }).toList(),

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
                    // Panggil fungsi edit dari mixin
                    showEditQuizDialog(quiz);
                  } else if (result == 'delete') {
                    // Panggil fungsi hapus dari mixin
                    showDeleteQuizConfirmation(widget.course.courseId, quiz); 
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: Text('Edit Kuis'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Text('Hapus Kuis', style: TextStyle(color: Colors.red)),
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
  // --- END WIDGET HELPER INLINE ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.course.title),
        backgroundColor: Colors.green,
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
              return Center(child: Text('Error: ${snapshot.error}'));
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
}
