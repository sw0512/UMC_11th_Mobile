import 'package:shared_preferences/shared_preferences.dart';

class EmailPreference {
  static const key = 'movielog.remembered_email';
  Future<String?> read() async =>
      (await SharedPreferences.getInstance()).getString(key);
  Future<void> save(String? email) async {
    final prefs = await SharedPreferences.getInstance();
    if (email == null) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, email.trim());
    }
  }
}
