import 'package:shared_preferences/shared_preferences.dart';

class UserPrefs {
  static const _kName = 'display_name';

  static Future<void> setName(String name) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kName, name.trim());
  }

  static Future<String?> getName() async {
    final sp = await SharedPreferences.getInstance();
    final v = sp.getString(_kName);
    if (v == null || v.trim().isEmpty) return null;
    return v.trim();
  }

  static Future<void> clearName() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kName);
  }
}
