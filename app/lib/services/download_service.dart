import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class DownloadService {
  static final _notificationsPlugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> _initNotifications() async {
    if (_initialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _notificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (_) {},
    );
    _initialized = true;
  }

  static Future<bool> _requestPermissions() async {
    if (Platform.isAndroid || Platform.isIOS) {
      await Permission.notification.request();
    }
    if (Platform.isAndroid) {
      await Permission.storage.request();
    }
    return true;
  }

  static Future<String?> downloadPDF({
    required String url,
    required String fileName,
  }) async {
    try {
      await _initNotifications();
      await _requestPermissions();

      String savePath;

      if (Platform.isAndroid) {
        savePath = '/storage/emulated/0/Download/$fileName.pdf';
      } else if (Platform.isIOS) {
        final dir = await getApplicationDocumentsDirectory();
        savePath = '${dir.path}/$fileName.pdf';
      } else {
        final dir = await getDownloadsDirectory();
        savePath = '${dir?.path ?? ""}/$fileName.pdf';
      }

      final dio = Dio();
      await dio.download(url, savePath);
      await _showNotification('Download Complete', 'Saved $fileName.pdf');
      return savePath;
    } catch (e) {
      await _showNotification('Download Failed', 'Could not download meeting PDF.');
      return null;
    }
  }

  static Future<void> _showNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'downloads_channel',
      'Downloads',
      channelDescription: 'Notifications for downloaded files',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }
}