import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/streak.dart';

class StreakService {
  static const _streakKey = "streak";

  // Load streak data from storage
  static Future<Streak> loadStreak() async {
    final sp = await SharedPreferences.getInstance();
    final txt = sp.getString(_streakKey);
    if (txt == null) return Streak();
    return Streak.fromJson(jsonDecode(txt));
  }

  // Save streak data to storage
  static Future<void> saveStreak(Streak streak) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_streakKey, jsonEncode(streak.toJson()));
  }

  // Update streak when user captures an insect
  static Future<Streak> updateStreak() async {
    final streak = await loadStreak();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (streak.lastActivityDate == null) {
      // First capture ever
      final newStreak = Streak(
        currentStreak: 1,
        longestStreak: 1,
        lastActivityDate: today,
      );
      await saveStreak(newStreak);
      return newStreak;
    }

    final lastActivity = DateTime(
      streak.lastActivityDate!.year,
      streak.lastActivityDate!.month,
      streak.lastActivityDate!.day,
    );

    if (lastActivity == today) {
      // Already counted today
      return streak;
    }

    final daysDifference = today.difference(lastActivity).inDays;

    if (daysDifference == 1) {
      // Consecutive day - increment streak
      final newCurrent = streak.currentStreak + 1;
      final newLongest = newCurrent > streak.longestStreak ? newCurrent : streak.longestStreak;
      final newStreak = Streak(
        currentStreak: newCurrent,
        longestStreak: newLongest,
        lastActivityDate: today,
      );
      await saveStreak(newStreak);
      return newStreak;
    } else {
      // Streak broken - reset to 1
      final newStreak = Streak(
        currentStreak: 1,
        longestStreak: streak.longestStreak,
        lastActivityDate: today,
      );
      await saveStreak(newStreak);
      return newStreak;
    }
  }

  // Get current streak info
  static Future<Streak> getCurrentStreak() async {
    return await loadStreak();
  }
}
