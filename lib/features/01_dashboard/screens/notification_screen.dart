// lib/features/01_dashboard/screens/notification_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/notification_model.dart';
import '../../../core/services/data_service.dart';
import '../../../core/providers/auth_provider.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late Future<List<NotificationModel>> _notifFuture;
  late DataService _dataService;

  @override
  void initState() {
    super.initState();
    _dataService = DataService(context);
    _notifFuture = _dataService.fetchNotifications();
    _markAllAsRead(); // Otomatis tandai semua terbaca saat dibuka
  }

  Future<void> _markAllAsRead() async {
    // Panggil API untuk tandai semua sudah dibaca
    await _dataService.markAllRead();
    if (mounted) {
      // Update badge notifikasi di AppBar utama agar hilang (jadi 0)
      Provider.of<AuthProvider>(
        context,
        listen: false,
      ).checkUnreadNotifications();
    }
  }

  // --- Helper: Membuat Judul Grup (Hari ini, Kemarin, atau Tanggal) ---
  String _getGroupHeader(String createdAt) {
    // Parse string tanggal dari Laravel (contoh: 2025-11-26 14:30:00)
    final date = DateTime.tryParse(createdAt);
    if (date == null) return 'Lainnya';

    final now = DateTime.now();
    // Kita hanya bandingkan Tanggal/Bulan/Tahun (abaikan jam)
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (targetDate == today) {
      return 'Hari ini';
    } else if (targetDate == yesterday) {
      return 'Kemarin';
    } else {
      // Format Tanggal Manual: "22 Nov 2025"
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Ags',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        elevation: 1,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 4, 31, 184),
                Color.fromARGB(255, 77, 80, 255),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<NotificationModel>>(
        future: _notifFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 60,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Belum ada notifikasi",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final notifs = snapshot.data!;

          // --- LOGIKA PENGELOMPOKAN (GROUPING) ---
          // Map: "Hari ini" -> [Notif1, Notif2], "22 Nov" -> [Notif3]
          Map<String, List<NotificationModel>> groupedNotifs = {};

          for (var notif in notifs) {
            String header = _getGroupHeader(notif.createdAt);
            if (!groupedNotifs.containsKey(header)) {
              groupedNotifs[header] = [];
            }
            groupedNotifs[header]!.add(notif);
          }

          // Ambil daftar key (tanggal)
          final headers = groupedNotifs.keys.toList();

          return ListView.builder(
            itemCount: headers.length,
            itemBuilder: (context, index) {
              String header = headers[index];
              List<NotificationModel> items = groupedNotifs[header]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. TAMPILKAN HEADER TANGGAL
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Text(
                      header,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ),

                  // 2. TAMPILKAN LIST NOTIFIKASI DI BAWAHNYA
                  ...items.map((notif) => _buildNotifTile(notif)).toList(),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // Helper untuk tampilan 1 baris notifikasi
  Widget _buildNotifTile(NotificationModel notif) {
    IconData icon;
    Color color;

    switch (notif.type) {
      case 'success':
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case 'warning':
        icon = Icons.warning_amber_rounded;
        color = Colors.orange;
        break;
      default:
        icon = Icons.info;
        color = Colors.blue;
    }

    return Container(
      color: notif.isRead
          ? Colors.white
          : Colors.blue[50], // Highlight biru muda jika belum dibaca
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(
          notif.title,
          style: TextStyle(
            fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(notif.body),
            const SizedBox(height: 6),
            // Tampilkan JAM saja (karena tanggal sudah di header)
            Builder(
              builder: (context) {
                try {
                  final date = DateTime.parse(notif.createdAt).toLocal();
                  // Tampilkan Jam dan Menit saja (karena tanggal sudah di header)
                  return Text(
                    DateFormat('HH:mm').format(date),
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  );
                } catch (e) {
                  return const Text("-");
                }
              },
            ),
          ],
        ),
        onTap: () {
          // Opsional: Navigasi ke detail jika perlu
        },
      ),
    );
  }
}
