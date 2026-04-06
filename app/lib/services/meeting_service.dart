import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class MeetingService {

  static const String baseUrl = "https://smart-mom.onrender.com/meetings";

  static Future getMeetings() async {
    return await ApiService.get("meetings");
  }

  static Future createMeeting(Map data) async {
    return await ApiService.post("meetings/create", data);
  }

  static Future deleteMeeting(String id) async {
    return await ApiService.delete("meetings/$id");
  }

  /// RETURN EXPORT URL
  static Future<String> exportMeetingUrl(String id) async {

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    return "$baseUrl/export/$id?token=$token";

  }

}

