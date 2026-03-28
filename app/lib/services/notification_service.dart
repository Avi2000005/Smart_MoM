// app/lib/services/notification_service.dart
import 'api_service.dart';

class NotificationService {
  static Future<List<dynamic>> getNotifications() async {
    final res = await ApiService.get("notifications");
    if (res is List) return res;
    return [];
  }

  static Future<int> getUnreadCount() async {
    final res = await ApiService.get("notifications/unread-count");
    return res["count"] ?? 0;
  }

  static Future<void> markAllRead() async {
    await ApiService.patch("notifications/read-all", {});
  }

  static Future<void> markOneRead(String id) async {
    await ApiService.patch("notifications/$id/read", {});
  }

  static Future<void> deleteNotification(String id) async {
    await ApiService.delete("notifications/$id");
  }
}