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

    const androidInit = AndroidInitializationSettings('ic_launcher');
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
      try {
        await Permission.notification.request();
      } catch (_) {} // Ignore if notification request fails
    }
    // We no longer request storage permission as we use getApplicationDocumentsDirectory
    // which does not require any permissions and avoids hanging on Android 13+.
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

      // Sanitize the filename to avoid file system exceptions
      final sanitizedFileName = fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '');

      if (Platform.isAndroid || Platform.isIOS) {
        final dir = await getApplicationDocumentsDirectory();
        savePath = '${dir.path}/$sanitizedFileName.pdf';
      } else {
        final dir = await getDownloadsDirectory();
        savePath = '${dir?.path ?? ""}/$sanitizedFileName.pdf';
      }

      final dio = Dio(
        BaseOptions(
           connectTimeout: const Duration(seconds: 30),
           receiveTimeout: const Duration(seconds: 45),
        )
      );
      await dio.download(url, savePath);
      await _showNotification('Download Complete', 'Saved $sanitizedFileName.pdf');
      return savePath;
    } catch (e) {
      print("PDF Download Error: $e");
      await _showNotification('Download Failed', 'Error: ${e.toString()}');
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