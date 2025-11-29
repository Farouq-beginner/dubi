import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // 1. Inisialisasi (Panggil di main.dart)
  static Future<void> initialize() async {
    // Setup Icon Android (Pastikan @mipmap/ic_launcher ada, ini default Flutter)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Setup iOS (Standar)
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _notificationsPlugin.initialize(initializationSettings);

    // Request Izin Notifikasi (Khusus Android 13+)
    await Permission.notification.request();
  }

  // 2. Tampilkan Notifikasi
  static Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'dubi_channel_01', // ID Channel unik
      'DuBI Notifikasi', // Nama Channel yang muncul di setting HP
      channelDescription: 'Pemberitahuan aktivitas belajar',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(
      DateTime.now().millisecond, // ID unik (random)
      title,
      body,
      platformDetails,
    );
  }
}