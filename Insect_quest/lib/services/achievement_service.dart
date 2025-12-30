import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/achievement.dart';
import '../models/capture.dart';
import '../models/streak.dart';

class AchievementService {
  static const _achievementsKey = "achievements";

  // Initialize default achievements
  static List<Achievement> _defaultAchievements() {
    return [
      // Set completion achievements
      Achievement(
        id: "butterfly_collector",
        title: "Butterfly Collector",
        description: "Capture all butterfly species in the catalog",
        type: AchievementType.setCompletion,
        criteria: {"group": "Butterflies", "count": 4},
        coinReward: 500,
      ),
      Achievement(
        id: "bee_keeper",
        title: "Bee Keeper",
        description: "Capture all bee and wasp species",
        type: AchievementType.setCompletion,
        criteria: {"group": "Bees/Wasps", "count": 3},
        coinReward: 400,
      ),
      Achievement(
        id: "spider_expert",
        title: "Spider Expert",
        description: "Capture all spider species",
        type: AchievementType.setCompletion,
        criteria: {"group": "Arachnids - Spiders", "count": 3},
        coinReward: 400,
      ),
      
      // Milestone achievements
      Achievement(
        id: "first_capture",
        title: "First Capture",
        description: "Capture your first insect",
        type: AchievementType.milestone,
        criteria: {"total_captures": 1},
        coinReward: 50,
      ),
      Achievement(
        id: "ten_captures",
        title: "Getting Started",
        description: "Capture 10 insects",
        type: AchievementType.milestone,
        criteria: {"total_captures": 10},
        coinReward: 150,
      ),
      Achievement(
        id: "fifty_captures",
        title: "Dedicated Collector",
        description: "Capture 50 insects",
        type: AchievementType.milestone,
        criteria: {"total_captures": 50},
        coinReward: 500,
      ),
      Achievement(
        id: "hundred_captures",
        title: "Master Collector",
        description: "Capture 100 insects",
        type: AchievementType.milestone,
        criteria: {"total_captures": 100},
        coinReward: 1000,
      ),
      
      // Streak achievements
      Achievement(
        id: "week_streak",
        title: "Weekly Explorer",
        description: "Maintain a 7-day streak",
        type: AchievementType.streak,
        criteria: {"streak_days": 7},
        coinReward: 200,
      ),
      Achievement(
        id: "month_streak",
        title: "Monthly Explorer",
        description: "Maintain a 30-day streak",
        type: AchievementType.streak,
        criteria: {"streak_days": 30},
        coinReward: 1000,
      ),
      
      // Region/habitat achievements
      Achievement(
        id: "urban_explorer",
        title: "Urban Explorer",
        description: "Capture 20 insects in urban areas",
        type: AchievementType.regionCompletion,
        criteria: {"region": "urban", "count": 20},
        coinReward: 300,
      ),
    ];
  }

  // Load achievements from storage
  static Future<List<Achievement>> loadAchievements() async {
    final sp = await SharedPreferences.getInstance();
    final txt = sp.getString(_achievementsKey);
    
    if (txt == null) {
      // First time - initialize with defaults
      final defaults = _defaultAchievements();
      await saveAchievements(defaults);
      return defaults;
    }
    
    final arr = jsonDecode(txt) as List<dynamic>;
    return arr
        .map((e) => Achievement.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // Save achievements to storage
  static Future<void> saveAchievements(List<Achievement> achievements) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_achievementsKey,
        jsonEncode(achievements.map((e) => e.toJson()).toList()));
  }

  // Check and unlock achievements based on captures
  static Future<List<Achievement>> checkAchievements(
      List<Capture> captures, Streak streak) async {
    final achievements = await loadAchievements();
    final newlyUnlocked = <Achievement>[];

    for (var i = 0; i < achievements.length; i++) {
      final achievement = achievements[i];
      if (achievement.unlocked) continue;

      bool shouldUnlock = false;

      switch (achievement.type) {
        case AchievementType.setCompletion:
          shouldUnlock = _checkSetCompletion(achievement, captures);
          break;
        case AchievementType.milestone:
          shouldUnlock = _checkMilestone(achievement, captures);
          break;
        case AchievementType.streak:
          shouldUnlock = _checkStreak(achievement, streak);
          break;
        case AchievementType.regionCompletion:
          shouldUnlock = _checkRegionCompletion(achievement, captures);
          break;
        case AchievementType.habitatCompletion:
          shouldUnlock = _checkHabitatCompletion(achievement, captures);
          break;
      }

      if (shouldUnlock) {
        achievements[i] = achievement.copyWith(
          unlocked: true,
          unlockedAt: DateTime.now(),
        );
        newlyUnlocked.add(achievements[i]);
      }
    }

    if (newlyUnlocked.isNotEmpty) {
      await saveAchievements(achievements);
    }

    return newlyUnlocked;
  }

  static bool _checkSetCompletion(Achievement achievement, List<Capture> captures) {
    final group = achievement.criteria["group"] as String?;
    final requiredCount = achievement.criteria["count"] as int? ?? 0;
    
    if (group == null) return false;
    
    final uniqueSpecies = <String>{};
    for (final capture in captures) {
      if (capture.group == group && capture.species != null) {
        uniqueSpecies.add(capture.species!);
      }
    }
    
    return uniqueSpecies.length >= requiredCount;
  }

  static bool _checkMilestone(Achievement achievement, List<Capture> captures) {
    final requiredCaptures = achievement.criteria["total_captures"] as int? ?? 0;
    return captures.length >= requiredCaptures;
  }

  static bool _checkStreak(Achievement achievement, Streak streak) {
    final requiredDays = achievement.criteria["streak_days"] as int? ?? 0;
    return streak.currentStreak >= requiredDays;
  }

  static bool _checkRegionCompletion(Achievement achievement, List<Capture> captures) {
    final region = achievement.criteria["region"] as String?;
    final requiredCount = achievement.criteria["count"] as int? ?? 0;
    
    if (region == null) return false;
    
    // TODO: Region data not yet implemented in Capture model
    // This is a placeholder that counts all captures
    // Future enhancement: Add region field to Capture and filter by it
    return captures.length >= requiredCount;
  }

  static bool _checkHabitatCompletion(Achievement achievement, List<Capture> captures) {
    final habitat = achievement.criteria["habitat"] as String?;
    final requiredCount = achievement.criteria["count"] as int? ?? 0;
    
    if (habitat == null) return false;
    
    // TODO: Habitat data not yet implemented in Capture model
    // This is a placeholder that counts all captures
    // Future enhancement: Add habitat field to Capture and filter by it
    return captures.length >= requiredCount;
  }
}
