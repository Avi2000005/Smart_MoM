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


  // Add to your existing AuthService class

static Future<void> forgotPassword(String email) async {
  final res = await ApiService.post("auth/forgot-password", {"email": email});
  if (res["message"] == null) throw Exception("Failed to send OTP");
}

static Future<String> verifyResetOtp(String email, String otp) async {
  final res = await ApiService.post("auth/verify-reset-otp", {
    "email": email,
    "otp":   otp,
  });
  if (res["resetToken"] == null) {
    throw Exception(res["message"] ?? "Invalid OTP");
  }
  return res["resetToken"];
}

static Future<void> resetPassword(
  String email,
  String resetToken,
  String newPassword,
) async {
  final res = await ApiService.post("auth/reset-password", {
    "email":       email,
    "resetToken":  resetToken,
    "newPassword": newPassword,
  });
  if (res["message"] != "Password reset successful. Please log in.") {
    throw Exception(res["message"] ?? "Reset failed");
  }
}
 
  // ── Logout ─────────────────────────────────────────────────────────────────
 
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");
  }
}