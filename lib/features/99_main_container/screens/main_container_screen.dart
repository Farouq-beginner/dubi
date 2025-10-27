// lib/features/99_main_container/screens/main_container_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/models/subject_model.dart';

// Import semua layar yang akan menjadi Tab
import '../../01_dashboard/screens/browse_screen.dart';
import '../../01_dashboard/screens/home_screen.dart';
import '../../01_dashboard/screens/student_progress_screen.dart';
import '../../02_profile/screens/profile_screen.dart';
import '../../03_course/screens/subject_courses_screen.dart';
import '../../06_sempoa/screens/sempoa_screen.dart'; // <-- Import SempoaScreen

class MainContainerScreen extends StatefulWidget {
  const MainContainerScreen({Key? key}) : super(key: key);

  @override
  State<MainContainerScreen> createState() => _MainContainerScreenState();
}

class _MainContainerScreenState extends State<MainContainerScreen> {
  int _selectedIndex = 0; 
  late List<Widget> _widgetOptions;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    final userRole = Provider.of<AuthProvider>(context, listen: false).user?.role;

    // Tentukan Layar Dashboard (Tab 2) berdasarkan Role
    Widget dashboardTabScreen;
    if (userRole == 'student') {
      dashboardTabScreen = const StudentProgressScreen();
    } else {
      dashboardTabScreen = const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text(
            'Dashboard Progres hanya tersedia untuk akun Siswa.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    // Daftar 5 Layar Final
    _widgetOptions = <Widget>[
      const BrowseScreen(),      // Indeks 0: Beranda
      const HomeScreen(),        // Indeks 1: Course (Kursus Saya)
      dashboardTabScreen,        // Indeks 2: Dashboard
      const SempoaScreen(),      // Indeks 3: Sempoa
      const ProfileScreen(),     // Indeks 4: Profil
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      // --- [PERBAIKAN] AppBar Kustom Statis ---
      appBar: AppBar(
        title: Row(
          children: [
            // Logo (jika Anda punya gambar logo)
            // Image.asset('assets/logo.png', height: 36), 
            // atau Ikon:
            Icon(Icons.book, color: Colors.white, size: 30),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DuBI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
                Text('Dunia Belajar Interactive', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.green, // Tema hijau
        actions: [
          IconButton(icon: Icon(Icons.search, color: Colors.white), onPressed: () {}),
          IconButton(icon: Icon(Icons.notifications_none, color: Colors.white), onPressed: () {}),
        ],
        elevation: 0,
      ),
      // ----------------------------------------
      
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Wajib untuk 5 item
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school_outlined),
            activeIcon: Icon(Icons.school),
            label: 'Course',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calculate_outlined),
            activeIcon: Icon(Icons.calculate),
            label: 'Sempoa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green[800], // Sesuaikan dengan tema DuBI
        unselectedItemColor: Colors.grey[600],
        onTap: _onItemTapped,
      ),
    );
  }
}