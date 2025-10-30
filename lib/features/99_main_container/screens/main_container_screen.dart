import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers/auth_provider.dart';

// Import layar-layar
import '../../01_dashboard/screens/admin_user_management_screen.dart';
import '../../01_dashboard/screens/browse_screen.dart';
import '../../01_dashboard/screens/home_screen.dart';
import '../../01_dashboard/screens/student_progress_screen.dart';
import '../../02_profile/screens/profile_screen.dart';
import '../../06_sempoa/screens/sempoa_screen.dart';
import '../../01_dashboard/screens/teacher_dashboard_screen.dart';

class MainContainerScreen extends StatefulWidget {
  const MainContainerScreen({Key? key}) : super(key: key);

  static void switchTo(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<_MainContainerScreenState>();
    state?._onItemTapped(index);
  }

  @override
  State<MainContainerScreen> createState() => _MainContainerScreenState();
}

class _MainContainerScreenState extends State<MainContainerScreen> {
  int _selectedIndex = 0;
  late List<Widget> _widgetOptions;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final userRole = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).user?.role;

    Widget dashboardTabScreen;
    if (userRole == 'student') {
      dashboardTabScreen = const StudentProgressScreen();
    } else if (userRole == 'teacher') {
      dashboardTabScreen = const TeacherDashboardScreen();
    } else if (userRole == 'admin') {
      dashboardTabScreen = const AdminUserManagementScreen();
    } else {
      dashboardTabScreen = const Center(child: Text('Role tidak dikenal.'));
    }

    _widgetOptions = <Widget>[
      const BrowseScreen(),
      const HomeScreen(),
      dashboardTabScreen,
      const SempoaScreen(),
      const ProfileScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  // 🔧 Item ikon + teks + animasi bounce
  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    final color = isActive ? Colors.white : Colors.white70;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 🎯 Efek bounce hanya pada item aktif
        isActive
            ? BounceInDown(
                duration: const Duration(milliseconds: 400),
                from: 8,
                child: Icon(icon, size: 28, color: color),
              )
            : Icon(icon, size: 26, color: color),
        // Hide label if active (in page)
        if (!isActive) ...[
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.normal,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 🌿 AppBar branding DuBI
      appBar: AppBar(
        backgroundColor: Colors.lightBlueAccent.shade100,
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.menu_book_rounded, color: Colors.white, size: 32),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DuBI',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.15),
                        offset: const Offset(1, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                Text(
                  'Dunia Belajar Interaktif',
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: Colors.white70, // lembut, kontras pas
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ],
        ),

        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF80D8FF), Color(0xFF4FC3F7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),

        actions: const [
          Icon(Icons.search, color: Colors.white),
          SizedBox(width: 8),
          Icon(Icons.notifications_none, color: Colors.white),
          SizedBox(width: 8),
        ],
      ),

      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, anim) =>
            FadeTransition(opacity: anim, child: child),
        child: _widgetOptions.elementAt(_selectedIndex),
      ),

      bottomNavigationBar: CurvedNavigationBar(
        index: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.transparent,
        color: Colors.lightBlueAccent.shade100,
        buttonBackgroundColor: Colors.lightBlueAccent.shade200,
        height: 70,
        animationDuration: const Duration(milliseconds: 300),
        items: [
          _buildNavItem(Icons.home, 'Beranda', _selectedIndex == 0),
          _buildNavItem(Icons.school, 'Course', _selectedIndex == 1),
          _buildNavItem(Icons.dashboard, 'Dashboard', _selectedIndex == 2),
          _buildNavItem(Icons.calculate, 'Sempoa', _selectedIndex == 3),
          _buildNavItem(Icons.person, 'Profil', _selectedIndex == 4),
        ],
      ),
    );
  }
}
