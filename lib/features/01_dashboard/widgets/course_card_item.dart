// lib/features/01_dashboard/widgets/course_card_item.dart
import 'package:flutter/material.dart';
import '../../../core/models/course_model.dart';

class CourseCardItem extends StatelessWidget {
  final Course course;
  final String? levelTag; // override level badge text if provided
  final VoidCallback? onTap;
  final VoidCallback? onStart;

  const CourseCardItem({
    super.key,
    required this.course,
    this.levelTag,
    this.onTap,
    this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final levelText = levelTag ?? (course.level?.levelName ?? '');
    final subjectText = course.subject.subjectName;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon bubble
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF7C7CFF),
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C8BFF), Color(0xFF9F7CFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(Icons.menu_book_rounded, color: Colors.white),
            ),
            const SizedBox(width: 14),

            // Title + subtitle + subject chip
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (course.description.isNotEmpty)
                    Text(
                      course.description,
                      style: TextStyle(fontSize: 13, color: Colors.black.withValues(alpha: 0.6)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      subjectText,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Right column: level badge + start button below it
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (levelText.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      levelText,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                const SizedBox(height: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  onPressed: onStart ?? onTap,
                  child: const Text('Mulai'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
