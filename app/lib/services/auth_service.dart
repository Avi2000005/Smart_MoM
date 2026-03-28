import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService {

  static Future login(String email,String password) async {

    final res = await ApiService.post(
      "auth/login",
      {
        "email": email,
        "password": password
      },
    );

    if(res["token"] != null){

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("token", res["token"]);

    }

    return res;

  }

  static Future register(String username,String email,String password) async {

    final res = await ApiService.post(
      "auth/register",
      {
        "username": username,
        "email": email,
        "password": password
      },
    );

    if(res["token"] != null){

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("token", res["token"]);

    }

    return res;

  }

  static Future logout() async {

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");

  }

}