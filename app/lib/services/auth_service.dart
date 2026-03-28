// services/auth_service.dart
 
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
 
class AuthService {
 
  // ── Login ──────────────────────────────────────────────────────────────────
 
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
 
    final res = await ApiService.post(
      "auth/login",
      {"email": email, "password": password},
    );
 
    if (res["token"] != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("token", res["token"]);
    }
 
    return res;
  }
 
  // ── Register ───────────────────────────────────────────────────────────────
  // Returns the server response map.
  // On success: { message, email }
  // Caller should navigate to OTP verification screen passing the email.
 
  static Future<Map<String, dynamic>> register(
    String username,
    String email,
    String password, {
    String mobile = "",
  }) async {
 
    final body = {
      "username": username,
      "email":    email,
      "password": password,
    };
 
    if (mobile.isNotEmpty) body["mobile"] = mobile;
 
    final res = await ApiService.post("auth/register", body);
 
    return res;
  }
 
  // ── Verify Email OTP ───────────────────────────────────────────────────────
  // Returns { message, token, user } on success.
 
  static Future<Map<String, dynamic>> verifyEmail(
    String email,
    String otp,
  ) async {
 
    final res = await ApiService.post(
      "auth/verify-email",
      {"email": email, "otp": otp},
    );
 
    if (res["token"] != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("token", res["token"]);
    }
 
    return res;
  }
 
  // ── Resend OTP ─────────────────────────────────────────────────────────────
 
  static Future<Map<String, dynamic>> resendOTP(String email) async {
    return await ApiService.post("auth/resend-otp", {"email": email});
  }
 
  // ── Logout ─────────────────────────────────────────────────────────────────
 
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");
  }
}