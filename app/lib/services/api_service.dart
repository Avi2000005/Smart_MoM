import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';


class ApiService {

  static const String baseUrl = "http://127.0.0.1:5000/api";

  static Future<String?> getToken() async {

  final prefs = await SharedPreferences.getInstance();

  return prefs.getString("token");

}

  static Future<Map<String,String>> _headers() async {

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    return {
      "Content-Type": "application/json",
      if(token != null) "Authorization": "Bearer $token"
    };

  }

  static Future get(String endpoint) async {

    final res = await http.get(
      Uri.parse("$baseUrl/$endpoint"),
      headers: await _headers(),
    );

    return jsonDecode(res.body);

  }

  static Future post(String endpoint, Map data) async {

    final res = await http.post(
      Uri.parse("$baseUrl/$endpoint"),
      headers: await _headers(),
      body: jsonEncode(data),
    );

    return jsonDecode(res.body);

  }

  static Future patch(String endpoint, Map data) async {

    final res = await http.patch(
      Uri.parse("$baseUrl/$endpoint"),
      headers: await _headers(),
      body: jsonEncode(data),
    );

    return jsonDecode(res.body);

  }

  /// FIXED DELETE
  static Future delete(String endpoint) async {

    final res = await http.delete(
      Uri.parse("$baseUrl/$endpoint"),
      headers: await _headers(),
    );

    return jsonDecode(res.body);

  }

}