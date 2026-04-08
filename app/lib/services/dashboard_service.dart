import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DashboardService {

  static const baseUrl = "https://smart-mom.onrender.com/api/dashboard";

  static Future<Map<String, dynamic>> getDashboard() async {

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final res = await http.get(
      Uri.parse(baseUrl),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
    );

    print("Dashboard response: ${res.body}");

    if(res.statusCode == 200){
      return jsonDecode(res.body);
    }

    return {};
  }
}