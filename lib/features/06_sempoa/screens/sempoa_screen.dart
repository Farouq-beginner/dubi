// lib/features/06_sempoa/screens/sempoa_screen.dart
import 'package:flutter/material.dart';

class SempoaScreen extends StatelessWidget {
  const SempoaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1. HAPUS AppBar dari sini (karena sudah di-handle MainContainer)
      
      body: ListView( 
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- [PERBAIKAN] Teks Judul di Center ---
          Column(
            crossAxisAlignment: CrossAxisAlignment.center, // <-- Center horizontal
            children: [
              Text(
                'Sempoa Interaktif',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                textAlign: TextAlign.center, // <-- Center teks
              ),
              Text(
                'Belajar berhitung dengan sempoa digital',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center, // <-- Center teks
              ),
            ],
          ),
          // ------------------------------------------

          const SizedBox(height: 32),

          // Kartu "Sempoa Master"
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.purple[50],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.calculate, color: Colors.purple, size: 40),
                  ),
                  const SizedBox(height: 16),
                  
                  Text(
                    'Sempoa Master',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Latihan berhitung cepat dengan sempoa',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton.icon(
                    icon: const Icon(Icons.grid_on, color: Colors.white),
                    label: const Text('Mainkan Sempoa', style: TextStyle(color: Colors.white, fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Fitur Sempoa Interaktif belum terhubung.'))
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      
      // --- [PERBAIKAN] Hapus Floating Action Button ---
      floatingActionButton: null, 
      // ---------------------------------------------
    );
  }
}