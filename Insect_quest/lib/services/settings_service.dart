import 'package:shared_preferences/shared_preferences.dart';
import '../config/feature_flags.dart';

class SettingsService {
  static const _kidsModeKey = "kids_mode";
  static const _pinKey = "parental_pin";
  static const _pinSetupCompleteKey = "pin_setup_complete";

  static Future<bool> getKidsMode() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(_kidsModeKey) ?? Flags.kidsModeDefault;
  }

  static Future<void> setKidsMode(bool value) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kidsModeKey, value);
  }

  // PIN Management
  static Future<bool> isPinSetup() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(_pinSetupCompleteKey) ?? false;
  }

  static Future<void> setPin(String pin) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_pinKey, pin);
    await sp.setBool(_pinSetupCompleteKey, true);
  }

  static Future<bool> verifyPin(String pin) async {
    final sp = await SharedPreferences.getInstance();
    final storedPin = sp.getString(_pinKey);
    // Ensure PIN is actually set up before comparing
    if (storedPin == null || storedPin.isEmpty) {
      return false;
    }
    return storedPin == pin;
  }

  static Future<void> clearPin() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_pinKey);
    await sp.setBool(_pinSetupCompleteKey, false);
  }
}
