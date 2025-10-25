// screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/auth_provider.dart';
import '/models/course_model.dart';
import '/services/data_service.dart';
import 'package:dubi/features/03_course/screens/create_course_screen.dart';
import 'package:dubi/features/03_course/screens/course_detail_screen.dart';
import 'package:dubi/features/01_dashboard/widgets/course_bubble_clickable.dart'; // <-- Widget baru

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Course>> _coursesFuture;
  late DataService _dataService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _dataService = DataService(context);
    _coursesFuture = _dataService.fetchMyCourses(); // Panggil API dinamis
  }

  // Fungsi untuk refresh
  Future<void> _refreshCourses() async {
    setState(() {
      _coursesFuture = _dataService.fetchMyCourses();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Ambil role pengguna untuk tombol FAB
    final userRole = Provider.of<AuthProvider>(context, listen: false).user?.role;

    return Scaffold(
      // --- TIDAK ADA APPBAR DI SINI (pindah ke MainContainerScreen) ---

      body: RefreshIndicator(
        onRefresh: _refreshCourses,
        child: FutureBuilder<List<Course>>(
          future: _coursesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    userRole == 'teacher'
                        ? 'Anda belum membuat kursus.\nTekan + untuk memulai!'
                        : 'Belum ada kursus untuk jenjang Anda.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ),
              );
            }

            List<Course> courses = snapshot.data!;
            
            // --- [FITUR BARU] MENGELOMPOKKAN BERDASARKAN KATEGORI ---
            final Map<String, List<Course>> groupedCourses = {};
            for (var course in courses) {
              String subjectName = course.subject.subjectName;
              if (groupedCourses[subjectName] == null) {
                groupedCourses[subjectName] = [];
              }
              groupedCourses[subjectName]!.add(course);
            }
            // --------------------------------------------------

            // Ubah Map menjadi List Widget
            List<Widget> categoryWidgets = [];
            groupedCourses.forEach((subjectName, subjectCourses) {
              // 1. Judul Kategori
              categoryWidgets.add(
                Padding(
                  padding: const EdgeInsets.only(top: 24.0, bottom: 8.0, left: 16.0, right: 16.0),
                  child: Text(
                    subjectName,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ),
              );
              
              // 2. Daftar Kursus (Bubble)
              categoryWidgets.addAll(
                subjectCourses.map((course) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: CourseBubbleClickable(
                      course: course,
                      onTap: () {
                        // Buka Detail Kursus
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CourseDetailScreen(course: course),
                          ),
                        ).then((_) => _refreshCourses()); // Refresh saat kembali
                      },
                    ),
                  );
                }).toList(),
              );
            });
            
            // Tampilkan sebagai ListView
            return ListView(
              children: categoryWidgets,
            );
          },
        ),
      ),
      
      // Tombol FAB (Floating Action Button) untuk Guru/Admin
      floatingActionButton: (userRole == 'teacher' || userRole == 'admin')
          ? FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => CreateCourseScreen(),
                )).then((_) => _refreshCourses()); // Refresh saat kembali
              },
              child: Icon(Icons.add, color: Colors.white),
              backgroundColor: Colors.green,
            )
          : null,
    );
  }
}