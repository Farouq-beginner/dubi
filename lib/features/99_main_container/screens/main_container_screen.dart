import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/services/data_service.dart';
import '../../00_auth/screens/login_screen.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:animate_do/animate_do.dart';
// import 'package:google_fonts/google_fonts.dart';
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

class _MainContainerScreenState extends State<MainContainerScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  late List<Widget> _widgetOptions;
  bool _updateDialogShown = false; // prevent duplicate forced update dialogs

  // --- [BAGIAN BARU] Init & Dispose Observer ---
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Setelah login & masuk container, cek validitas sesi seperti di SmartSplash
    _authenticateUserSession();
    _checkUpdateFromProviderOrNetwork();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // --- [BAGIAN BARU] Logika Cek Saat Aplikasi Aktif ---
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Panggil fungsi cek sesi di AuthProvider Anda
      // Pastikan AuthProvider Anda memiliki method 'checkSession()' atau 'checkSessionValidity()'
      _authenticateUserSession();
      _checkUpdateFromProviderOrNetwork();
      print("App Resumed: Checking session...");
    }
  }
  // ---------------------------------------------

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

  // --- Session validity check (mirror SmartSplash) ---
  Future<void> _authenticateUserSession() async {
    final dataService = DataService(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isLoggedIn) return;

    // Tampilkan teks/indikator ringan opsional? (skip, fokus ke dialog)
    final sessionValid = await dataService.checkSessionValidity();
    if (!sessionValid) {
      // Hapus data lokal dulu agar state bersih
      await authProvider.logout();
      if (!mounted) return;

      // Tampilkan dialog sama seperti di SmartSplash
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text(
            'Sesi Berakhir',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Akun Anda telah login di perangkat lain atau sesi telah habis.\n\nSilakan login kembali.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx); // tutup dialog
              },
              child: const Text('OK, Ke Halaman Login'),
            ),
          ],
        ),
      );

      if (!mounted) return;
      // Arahkan ke Login setelah dialog ditutup
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  // --- In-app update check driven by AuthCheckScreen via AuthProvider ---
  Future<void> _checkUpdateFromProviderOrNetwork() async {
    if (_updateDialogShown) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.updateRequired) {
      _updateDialogShown = true;
      final info = auth.updateInfo ?? {};
      final url = (info['download_url'] ?? '').toString();
      final changelog = (info['changelog'] ?? 'Pembaruan tersedia.').toString();
      _showForceUpdateDialog(url, changelog);
      return;
    }

    // Otherwise, perform a quick network check to ensure dialog appears
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 1;
      final base = auth.dio.options.baseUrl;
      final root = base.endsWith('/api/') ? base.substring(0, base.length - 5) : base;
      final uri = Uri.parse('$root/api/check-update?build_number=$currentBuild');
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final latestBuild = int.tryParse(decoded['latest_build']?.toString() ?? '0') ?? 0;
          final forceUpdate = decoded['update_required'] == true;
          final downloadUrl = decoded['download_url']?.toString() ?? '';
          final changelog = decoded['changelog']?.toString() ?? 'Pembaruan tersedia.';
          if (forceUpdate && latestBuild > currentBuild) {
            _updateDialogShown = true;
            auth.setUpdateRequirement(required: true, info: {
              'latest_build': latestBuild,
              'download_url': downloadUrl,
              'changelog': changelog,
            });
            if (!mounted) return;
            _showForceUpdateDialog(downloadUrl, changelog);
          }
        }
      }
    } catch (e) {
      // ignore errors inside app
    }
  }

  Future<void> _showForceUpdateDialog(String url, String changelog) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text(
            '⚠️ Pembaruan Diperlukan',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Versi baru tersedia! Anda harus memperbarui aplikasi untuk melanjutkan.'),
              const SizedBox(height: 10),
              const Text('Apa yang baru:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(changelog),
            ],
          ),
          actions: [
            ElevatedButton.icon(
              onPressed: () async {
                if (url.isNotEmpty) {
                  final uri = Uri.parse(url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                }
              },
              icon: const Icon(Icons.download, color: Colors.white),
              label: const Text('Unduh Sekarang', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 4, 31, 184),
              ),
            ),
          ],
        ),
      ),
    );
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
            Icon(Icons.collections_bookmark_outlined, color: Colors.white, size: 40),
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
                        color: Colors.black.withValues(alpha: 0.15),
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
              colors: [Color.fromARGB(255, 4, 31, 184), Color.fromARGB(255, 77, 80, 255)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),

        actions: const [
          Icon(Icons.notifications_none, color: Colors.white),
          SizedBox(width: 8),
        ],
      ),

      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (child, anim) {
          final offsetAnim = Tween<Offset>(begin: const Offset(0.02, 0), end: Offset.zero).animate(anim);
          return FadeTransition(
            opacity: anim,
            child: SlideTransition(position: offsetAnim, child: child),
          );
        },
        // Penting: beri key unik per tab agar selalu terdeteksi berubah dan animasi jalan
        child: KeyedSubtree(
          key: ValueKey<int>(_selectedIndex),
          child: _widgetOptions.elementAt(_selectedIndex),
        ),
      ),

      bottomNavigationBar: CurvedNavigationBar(
        index: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.transparent,
        color: Color.fromARGB(255, 4, 31, 184),
        buttonBackgroundColor: Color.fromARGB(255, 77, 80, 255),
        height: 55,
        animationDuration: const Duration(milliseconds: 700),
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
