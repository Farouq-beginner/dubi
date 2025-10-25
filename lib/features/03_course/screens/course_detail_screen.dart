// screens/course_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Model yang diperlukan
import '../../../models/course_model.dart';
import '../../../models/lesson_model.dart';
import '../../../models/module_model.dart'; // <-- Diperlukan untuk tipe data
import '../../../models/course_detail_model.dart';
import '../../../models/quiz_model.dart';

// Service & Provider
import '../../../services/data_service.dart';
import '../../../providers/auth_provider.dart';

// Layar tujuan
import '../../04_lesson/screens/lesson_view_screen.dart';
import '../../05_quiz/quiz_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  final Course course;
  const CourseDetailScreen({Key? key, required this.course}) : super(key: key);

  @override
  _CourseDetailScreenState createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  late Future<CourseDetail> _detailFuture;
  late DataService _dataService;
  bool _isOwner = false; // State untuk cek kepemilikan

  // Kunci untuk me-refresh list secara manual
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Inisialisasi service dan cek kepemilikan di sini
    _dataService = DataService(context);
    
    // Cek kepemilikan
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _isOwner = auth.user?.userId == widget.course.createdByUserId;

    // Panggil future
    _detailFuture = _dataService.fetchCourseDetails(widget.course.courseId);
  }

  // Fungsi untuk me-refresh daftar modul
  Future<void> _refreshData() async {
    // Panggil ulang API
    setState(() {
      _detailFuture = _dataService.fetchCourseDetails(widget.course.courseId);
    });
  }

  // --- [BARU] Tampilkan Dialog untuk Tambah Modul ---
  void _showAddModuleDialog() {
    final titleController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Buat Modul Baru'),
          content: TextField(
            controller: titleController,
            decoration: InputDecoration(hintText: 'Judul Modul'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              child: Text('Batal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text('Simpan'),
              onPressed: () async {
                if (titleController.text.isEmpty) return;
                try {
                  await _dataService.createModule(
                    courseId: widget.course.courseId,
                    title: titleController.text,
                  );
                  Navigator.of(context).pop();
                  _refreshData(); // Refresh list
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  // --- [BARU] Tampilkan Dialog untuk Tambah Materi (Lesson) ---
  void _showAddLessonDialog(Module module) {
    final titleController = TextEditingController();
    final contentBodyController = TextEditingController(); // Untuk URL/Teks
    String contentType = 'video'; // Default

    showDialog(
      context: context,
      builder: (context) {
        // Gunakan StatefulBuilder agar Dropdown bisa di-update di dalam dialog
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Materi Baru: ${module.title}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(hintText: 'Judul Materi'),
                      autofocus: true,
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: contentType,
                      items: ['video', 'text', 'pdf'].map((type) {
                        return DropdownMenuItem(value: type, child: Text(type.toUpperCase()));
                      }).toList(),
                      onChanged: (val) {
                        setDialogState(() => contentType = val!);
                      },
                      decoration: InputDecoration(labelText: 'Tipe Konten'),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: contentBodyController,
                      decoration: InputDecoration(hintText: contentType == 'video' ? 'URL Video' : 'Isi Teks'),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text('Batal'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  child: Text('Simpan'),
                  onPressed: () async {
                    if (titleController.text.isEmpty) return;
                    try {
                      await _dataService.createLesson(
                        moduleId: module.moduleId,
                        title: titleController.text,
                        contentType: contentType,
                        contentBody: contentBodyController.text,
                      );
                      Navigator.of(context).pop();
                      _refreshData(); // Refresh list
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.course.title),
        backgroundColor: Colors.green,
      ),
      body: RefreshIndicator( // <-- Tambah RefreshIndicator
        key: _refreshIndicatorKey,
        onRefresh: _refreshData, // Panggil fungsi refresh
        child: FutureBuilder<CourseDetail>(
          future: _detailFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData) {
              return Center(child: Text('Data tidak ditemukan.'));
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

            // Gunakan ListView.builder untuk menggabungkan dua list
            return ListView.builder(
              padding: EdgeInsets.all(16),
              // Total item = jumlah modul + jumlah kuis + 2 judul (jika ada)
              itemCount: (modules.isNotEmpty ? modules.length + 1 : 0) +
                         (quizzes.isNotEmpty ? quizzes.length + 1 : 0),
              itemBuilder: (context, index) {
                
                // --- Judul "MODUL" ---
                if (modules.isNotEmpty && index == 0) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Text('Materi Belajar', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                  );
                }

                // --- List Modul ---
                int moduleIndex = index - 1;
                if (modules.isNotEmpty && moduleIndex < modules.length) {
                  final module = modules[moduleIndex];
                  return _buildModuleTile(module); // Widget Modul
                }

                // --- Judul "KUIS" ---
                int quizTitleIndex = modules.isNotEmpty ? modules.length + 1 : 0;
                if (quizzes.isNotEmpty && index == quizTitleIndex) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 24.0, bottom: 16.0),
                    child: Text('Uji Pemahaman (Kuis)', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                  );
                }

                // --- List Kuis ---
                int quizIndex = index - (modules.isNotEmpty ? modules.length + 1 : 0) - (quizzes.isNotEmpty ? 1 : 0);
                if (quizzes.isNotEmpty && quizIndex < quizzes.length) {
                  final quiz = quizzes[quizIndex];
                  return _buildQuizTile(quiz); // Widget Kuis
                }
                
                return Container(); // Fallback
              },
            );
          },
        ),
      ),
      // --- Tombol "Tambah Modul" ---
      floatingActionButton: _isOwner // Hanya tampil jika pemilik
          ? FloatingActionButton.extended(
              onPressed: _showAddModuleDialog,
              icon: Icon(Icons.add, color: Colors.white),
              label: Text('Tambah Modul', style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.green,
            )
          : null,
    );
  }
  
  // --- WIDGET HELPER BAWAAN ---

  // Widget untuk menampilkan 1 Modul
  Widget _buildModuleTile(Module module) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(module.title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green[800])),
        leading: Icon(Icons.folder_special, color: Colors.green, size: 30),
        initiallyExpanded: false,
        children: [
          // Jika tidak ada materi
          if (module.lessons.isEmpty && !_isOwner)
            ListTile(
              title: Text('Belum ada materi di modul ini.', style: TextStyle(fontStyle: FontStyle.italic)),
            ),
          
          // Daftar Materi (Lesson)
          ...module.lessons.map((Lesson lesson) { // Tipe data eksplisit
            return ListTile(
              title: Text(lesson.title),
              leading: Icon(lesson.contentType == 'video' ? Icons.play_circle_fill : Icons.article, color: Colors.grey[600]),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LessonViewScreen(lesson: lesson))),
            );
          }).toList(),
          
          // Tombol "Tambah Materi"
          if (_isOwner)
            ListTile(
              tileColor: Colors.blue[50],
              leading: Icon(Icons.add_box, color: Colors.blue[700]),
              title: Text('Tambah Materi Baru', style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.bold)),
              onTap: () {
                _showAddLessonDialog(module);
              },
            )
        ],
      ),
    );
  }

  // Widget untuk menampilkan 1 Kuis
  Widget _buildQuizTile(Quiz quiz) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(Icons.quiz, color: Colors.deepPurple, size: 30),
        title: Text(quiz.title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        subtitle: Text(quiz.description),
        trailing: Icon(Icons.arrow_forward_ios),
        onTap: () {
          // BUKA LAYAR KUIS
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => QuizScreen(quizId: quiz.quizId, quizTitle: quiz.title)),
          );
        },
      ),
    );
  }
}