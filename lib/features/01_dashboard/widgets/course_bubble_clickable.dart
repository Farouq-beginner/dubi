// lib/widgets/course_bubble_clickable.dart
import 'package:flutter/material.dart';
import '../../../core/models/course_model.dart'; // Pastikan path ini benar

class CourseBubbleClickable extends StatelessWidget {
  final Course course;
  final VoidCallback onTap;
  final VoidCallback? onDeleteAdmin; // <-- [PERBAIKAN] Tambahkan parameter ini

  const CourseBubbleClickable({
    Key? key,
    required this.course,
    required this.onTap,
    this.onDeleteAdmin, // <-- Tambahkan di constructor
  }) : super(key: key);

  // Helper untuk memilih ikon (gunakan kode Anda yang sudah ada)
  IconData _getIconForSubject(String subjectName) {
    // ... (kode ikon) ...
    if (subjectName.toLowerCase().contains('berhitung')) return Icons.calculate;
    if (subjectName.toLowerCase().contains('membaca')) return Icons.menu_book;
    if (subjectName.toLowerCase().contains('matematika')) return Icons.functions;
    return Icons.school;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.0),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.green[100],
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(color: Colors.green.shade300, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Ikon
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                child: Icon(_getIconForSubject(course.subject.subjectName), color: Colors.white, size: 30.0),
              ),
              const SizedBox(width: 16.0),
              // Teks (Title & Deskripsi)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(course.title, style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.green[900])),
                    const SizedBox(height: 4.0),
                    Text(course.description, style: const TextStyle(fontSize: 14.0, color: Colors.black54), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              
              // [FITUR ADMIN] Tombol Hapus Global (Jika callback ada)
              if (onDeleteAdmin != null)
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red[400]),
                  onPressed: onDeleteAdmin,
                )
              else
                // Indikator panah standar jika bukan Admin
                const Icon(Icons.chevron_right, color: Colors.grey, size: 28),
            ],
          ),
        ),
      ),
    );
  }
}