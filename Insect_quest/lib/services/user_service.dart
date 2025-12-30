import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class UserService {
  static const _userIdKey = "user_id";

  static Future<String> getUserId() async {
    final sp = await SharedPreferences.getInstance();
    String? userId = sp.getString(_userIdKey);
    if (userId == null) {
      userId = const Uuid().v4();
      await sp.setString(_userIdKey, userId);
    }
    return userId;
  }
}
