// widgets/course_bubble_clickable.dart
import 'package:flutter/material.dart';
import '/models/course_model.dart';

class CourseBubbleClickable extends StatelessWidget {
  final Course course;
  final VoidCallback onTap;

  const CourseBubbleClickable({Key? key, required this.course, required this.onTap}) : super(key: key);

  // Helper untuk memilih ikon
  IconData _getIconForSubject(String subjectName) {
    if (subjectName.toLowerCase().contains('berhitung')) {
      return Icons.calculate;
    }
    if (subjectName.toLowerCase().contains('membaca')) {
      return Icons.menu_book;
    }
     if (subjectName.toLowerCase().contains('matematika')) {
      return Icons.functions;
    }
    return Icons.school; // Default
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: InkWell( // <-- Dibungkus InkWell
        onTap: onTap, // <-- Panggil fungsi onTap
        borderRadius: BorderRadius.circular(20.0),
        child: Container(
          padding: EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.green[100],
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(color: Colors.green.shade300, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Ikon
              Container(
                padding: EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getIconForSubject(course.subject.subjectName),
                  color: Colors.white,
                  size: 30.0,
                ),
              ),
              SizedBox(width: 16.0),
              // Teks (Title & Deskripsi)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[900],
                      ),
                    ),
                    SizedBox(height: 4.0),
                    Text(
                      course.description,
                      style: TextStyle(
                        fontSize: 14.0,
                        color: Colors.black54,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Indikator panah
              Icon(Icons.chevron_right, color: Colors.green[800], size: 28),
            ],
          ),
        ),
      ),
    );
  }
}