import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quest.dart';
import '../models/capture.dart';
import 'package:uuid/uuid.dart';

class QuestService {
  static const _questsKey = "quests";
  static const _lastRefreshKey = "last_quest_refresh";
  static const _uuid = Uuid();

  // Load saved quests from storage
  static Future<List<Quest>> loadQuests() async {
    final sp = await SharedPreferences.getInstance();
    final txt = sp.getString(_questsKey);
    if (txt == null) return [];
    final arr = jsonDecode(txt) as List<dynamic>;
    return arr
        .map((e) => Quest.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // Save quests to storage
  static Future<void> saveQuests(List<Quest> quests) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(
        _questsKey, jsonEncode(quests.map((e) => e.toJson()).toList()));
  }

  // Check if quests need refresh (daily at midnight, weekly on Monday)
  static Future<bool> needsRefresh() async {
    final sp = await SharedPreferences.getInstance();
    final lastRefreshStr = sp.getString(_lastRefreshKey);
    if (lastRefreshStr == null) return true;

    final lastRefresh = DateTime.parse(lastRefreshStr);
    final now = DateTime.now();

    // Check if it's a new day (daily refresh)
    if (now.day != lastRefresh.day ||
        now.month != lastRefresh.month ||
        now.year != lastRefresh.year) {
      return true;
    }

    return false;
  }

  // Generate new quests for the day/week
  static Future<void> refreshQuests() async {
    final now = DateTime.now();
    final dailyExpiry = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final weekdayToMonday = (now.weekday - DateTime.monday) % 7;
    final weeklyExpiry = DateTime(now.year, now.month, now.day + (7 - weekdayToMonday), 23, 59, 59);

    // Generate 3 daily quests and 2 weekly quests
    final quests = <Quest>[
      // Daily quests
      Quest(
        id: _uuid.v4(),
        title: "Daily Explorer",
        description: "Photograph any insect",
        type: QuestType.captureAny,
        period: QuestPeriod.daily,
        requirements: {},
        coinReward: 50,
        expiresAt: dailyExpiry,
        target: 1,
      ),
      Quest(
        id: _uuid.v4(),
        title: "Pollinator Patrol",
        description: "Capture 2 pollinators (Butterflies or Bees/Wasps)",
        type: QuestType.captureGroup,
        period: QuestPeriod.daily,
        requirements: {"groups": ["Butterflies", "Bees/Wasps"]},
        coinReward: 75,
        expiresAt: dailyExpiry,
        target: 2,
      ),
      Quest(
        id: _uuid.v4(),
        title: "Urban Hunter",
        description: "Find 3 insects in urban areas",
        type: QuestType.captureCount,
        period: QuestPeriod.daily,
        requirements: {},
        coinReward: 100,
        expiresAt: dailyExpiry,
        target: 3,
      ),
      
      // Weekly quests
      Quest(
        id: _uuid.v4(),
        title: "Diversity Champion",
        description: "Capture 5 different species groups",
        type: QuestType.captureCount,
        period: QuestPeriod.weekly,
        requirements: {"uniqueGroups": true},
        coinReward: 250,
        foilReward: true,
        expiresAt: weeklyExpiry,
        target: 5,
      ),
      Quest(
        id: _uuid.v4(),
        title: "Quality Photographer",
        description: "Capture 3 insects with quality above 1.0",
        type: QuestType.captureQuality,
        period: QuestPeriod.weekly,
        requirements: {"minQuality": 1.0},
        coinReward: 200,
        expiresAt: weeklyExpiry,
        target: 3,
      ),
    ];

    await saveQuests(quests);

    // Update last refresh time
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_lastRefreshKey, now.toIso8601String());
  }

  // Update quest progress based on a new capture
  static Future<List<Quest>> updateQuestProgress(Capture capture) async {
    final quests = await loadQuests();
    final completedQuests = <Quest>[];

    // Get all captures to check unique groups for diversity quest
    final sp = await SharedPreferences.getInstance();
    final capturesStr = sp.getString("captures");
    final List<dynamic> capturesJson = capturesStr != null ? jsonDecode(capturesStr) : [];
    final allCaptures = capturesJson.map((e) => Capture.fromJson(Map<String, dynamic>.from(e))).toList();
    final uniqueGroups = allCaptures.map((c) => c.group).toSet();

    for (var i = 0; i < quests.length; i++) {
      final quest = quests[i];
      if (quest.completed || quest.claimed) continue;

      bool progressMade = false;

      switch (quest.type) {
        case QuestType.captureAny:
          quest.progress++;
          progressMade = true;
          break;

        case QuestType.captureGroup:
          final groups = quest.requirements["groups"] as List<dynamic>?;
          if (groups != null && groups.contains(capture.group)) {
            quest.progress++;
            progressMade = true;
          }
          break;

        case QuestType.captureQuality:
          final minQuality = quest.requirements["minQuality"] as double?;
          if (minQuality != null && capture.quality >= minQuality) {
            quest.progress++;
            progressMade = true;
          }
          break;

        case QuestType.captureTier:
          final tier = quest.requirements["tier"] as String?;
          if (tier != null && capture.tier == tier) {
            quest.progress++;
            progressMade = true;
          }
          break;

        case QuestType.captureCount:
          final uniqueGroupsRequired = quest.requirements["uniqueGroups"] as bool? ?? false;
          if (uniqueGroupsRequired) {
            // For diversity quests, update progress based on unique groups count
            quest.progress = uniqueGroups.length;
          } else {
            // For regular count quests, increment on any capture
            quest.progress++;
          }
          progressMade = true;
          break;

        case QuestType.captureSpecific:
          final species = quest.requirements["species"] as String?;
          if (species != null && capture.species == species) {
            quest.progress++;
            progressMade = true;
          }
          break;
      }

      // Check if quest is completed
      if (progressMade && quest.progress >= quest.target && !quest.completed) {
        quest.completed = true;
        completedQuests.add(quest);
      }

      quests[i] = quest;
    }

    await saveQuests(quests);
    return completedQuests;
  }

  // Claim quest reward
  static Future<void> claimReward(String questId) async {
    final quests = await loadQuests();
    for (var i = 0; i < quests.length; i++) {
      if (quests[i].id == questId && quests[i].completed && !quests[i].claimed) {
        quests[i] = quests[i].copyWith(claimed: true);
        break;
      }
    }
    await saveQuests(quests);
  }

  // Clean up expired quests
  static Future<void> cleanupExpiredQuests() async {
    final quests = await loadQuests();
    final now = DateTime.now();
    final activeQuests = quests.where((q) => q.expiresAt.isAfter(now)).toList();
    await saveQuests(activeQuests);
  }

  // Initialize quests system (call on app start)
  static Future<void> initialize() async {
    await cleanupExpiredQuests();
    
    if (await needsRefresh()) {
      await refreshQuests();
    }
  }
}
