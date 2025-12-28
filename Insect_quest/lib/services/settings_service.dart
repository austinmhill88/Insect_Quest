import 'package:shared_preferences/shared_preferences.dart';
import '../config/feature_flags.dart';

class SettingsService {
  static const _kidsModeKey = "kids_mode";

  static Future<bool> getKidsMode() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(_kidsModeKey) ?? Flags.kidsModeDefault;
  }

  static Future<void> setKidsMode(bool value) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kidsModeKey, value);
  }
}
