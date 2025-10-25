// screens/main_container_screen.dart
import 'package:flutter/material.dart';
import 'package:dubi/features/01_dashboard/screens/home_screen.dart';
import 'package:dubi/features/02_profile/screens/profile_screen.dart';

class MainContainerScreen extends StatefulWidget {
  const MainContainerScreen({Key? key}) : super(key: key);

  @override
  State<MainContainerScreen> createState() => _MainContainerScreenState();
}

class _MainContainerScreenState extends State<MainContainerScreen> {
  int _selectedIndex = 0; // 0 = Home, 1 = Profile

  // Daftar layar/widget untuk setiap tab
  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),    // Indeks 0
    ProfileScreen(), // Indeks 1
  ];

  // Daftar judul untuk AppBar
  static const List<String> _titles = <String>[
    'Dashboard Belajar',
    'Profil Saya',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        backgroundColor: Colors.green,
        automaticallyImplyLeading: false, // Sembunyikan tombol kembali
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green[800],
        onTap: _onItemTapped,
      ),
    );
  }
}