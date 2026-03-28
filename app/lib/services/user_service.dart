import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserService {

  static const String baseUrl = "http://127.0.0.1:5000/api/users";

  /// GET TOKEN FROM STORAGE
  static Future<Map<String,String>> _headers() async {

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    return {
      "Content-Type": "application/json",
      if(token != null) "Authorization": "Bearer $token"
    };

  }

  /// GET ALL USERS (for participants)
  static Future<List<dynamic>> getUsers() async {

    try {

      final response = await http.get(
        Uri.parse(baseUrl),
        headers: await _headers(),
      );

      if(response.statusCode == 200){
        return jsonDecode(response.body);
      }

      return [];

    } catch(e){

      print(e);
      return [];

    }

  }

  /// GET CURRENT LOGGED USER (for settings screen)
  static Future<Map<String,dynamic>> getCurrentUser() async {

    final response = await http.get(
      Uri.parse("$baseUrl/me"),
      headers: await _headers(),
    );

    return jsonDecode(response.body);

  }

  /// CHANGE PASSWORD
  static Future changePassword(String password) async {

    final response = await http.patch(
      Uri.parse("$baseUrl/password"),
      headers: await _headers(),
      body: jsonEncode({
        "password": password
      }),
    );

    return jsonDecode(response.body);

  }

}