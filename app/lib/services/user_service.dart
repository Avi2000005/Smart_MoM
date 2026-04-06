// lib/services/user_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserService {

  static const String baseUrl = "http://127.0.0.1:5000/api/users";
  //                                        ↑ Android emulator
  // Physical device → use your PC IP: http://192.168.x.x:5000/api/users

  // ── Get auth token ─────────────────────────────────────────────────────────
  static Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    return {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token"
    };
  }

  // ── GET ALL VERIFIED USERS (for participants chips) ────────────────────────
  static Future<List<dynamic>> getUsers() async {
    try {
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print("getUsers error: $e");
      return [];
    }
  }

  // ── SEARCH VERIFIED USERS by name or email ────────────────────────────────
  // Returns list of { _id, username, email }
  static Future<List<dynamic>> searchUsers(String query) async {
    try {
      if (query.trim().length < 2) return [];

      final response = await http.get(
        Uri.parse("$baseUrl/search?q=${Uri.encodeComponent(query)}"),
        headers: await _headers(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print("searchUsers error: $e");
      return [];
    }
  }

  // ── GET CURRENT LOGGED USER ────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await http.get(
      Uri.parse("$baseUrl/me"),
      headers: await _headers(),
    );
    return jsonDecode(response.body);
  }

  // ── CHANGE PASSWORD ────────────────────────────────────────────────────────
  static Future changePassword(String password) async {
    final response = await http.patch(
      Uri.parse("$baseUrl/password"),
      headers: await _headers(),
      body: jsonEncode({"password": password}),
    );
    return jsonDecode(response.body);
  }

}