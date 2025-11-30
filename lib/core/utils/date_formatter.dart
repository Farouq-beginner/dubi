import 'package:intl/intl.dart';

class DateFormatter {
  static String format(String dateString) {
    if (dateString.isEmpty) return '-';
    try {
      // Parse string dari server
      DateTime date = DateTime.parse(dateString);
      
      // Konversi ke Waktu Lokal HP Pengguna (penting jika user beda zona waktu)
      date = date.toLocal(); 
      
      // Format: "30 Nov 2025, 14:30"
      return DateFormat('d MMM yyyy, HH:mm').format(date);
    } catch (e) {
      return dateString;
    }
  }
}