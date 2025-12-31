import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/quest.dart';
import '../models/capture.dart';

class QuestService {
  static const _progressKey = "quest_progress";
  static const _questsKey = "quests";
  static const _lastRefreshKey = "last_quest_refresh";
  static const _uuid = Uuid();

  // Predefined quests - safe quests are kid-friendly
  static final List<Quest> allQuests = [
    // Safe learning quests for kids
    Quest.legacy(
      id: "butterfly_beginner",
      title: "Butterfly Beginner",
      description: "Photograph 3 butterflies and learn about their wings!",
      category: "learning",
      targetCount: 3,
      targetGroup: "Butterflies",
      safeForKids: true,
      rewardPoints: 100,
      emoji: "🦋",
    ),
    Quest.legacy(
      id: "bee_buddy",
      title: "Bee Buddy",
      description: "Find and photograph 2 bees. They help plants grow!",
      category: "learning",
      targetCount: 2,
      targetGroup: "Bees/Wasps",
      safeForKids: true,
      rewardPoints: 100,
      emoji: "🐝",
    ),
    Quest.legacy(
      id: "beetle_explorer",
      title: "Beetle Explorer",
      description: "Discover 2 different beetles in your area",
      category: "learning",
      targetCount: 2,
      targetGroup: "Beetles",
      safeForKids: true,
      rewardPoints: 100,
      emoji: "🪲",
    ),
    Quest.legacy(
      id: "first_five",
      title: "First Five Friends",
      description: "Capture your first 5 insects! Great start!",
      category: "collection",
      targetCount: 5,
      safeForKids: true,
      rewardPoints: 150,
      emoji: "⭐",
    ),
    Quest.legacy(
      id: "diversity_junior",
      title: "Diversity Explorer",
      description: "Find insects from 3 different groups",
      category: "exploration",
      targetCount: 3,
      safeForKids: true,
      rewardPoints: 200,
      emoji: "🌈",
    ),
    
    // Advanced quests (not necessarily unsafe, but more challenging)
    Quest.legacy(
      id: "spider_watcher",
      title: "Spider Watcher",
      description: "Observe and photograph 3 spiders safely from a distance",
      category: "exploration",
      targetCount: 3,
      targetGroup: "Arachnids – Spiders",
      safeForKids: false, // requires extra caution
      rewardPoints: 150,
      emoji: "🕷️",
    ),
    Quest.legacy(
      id: "collector_pro",
      title: "Collector Pro",
      description: "Capture 20 total insects",
      category: "collection",
      targetCount: 20,
      safeForKids: false, // advanced goal
      rewardPoints: 300,
      emoji: "🏆",
    ),
    Quest.legacy(
      id: "state_species_hunter",
      title: "State Species Hunter",
      description: "Find a Georgia state species!",
      category: "exploration",
      targetCount: 1,
      safeForKids: true,
      rewardPoints: 250,
      emoji: "🌟",
    ),
  ];

  // Get quests filtered by Kids Mode
  static List<Quest> getAvailableQuests(bool kidsMode) {
    if (kidsMode) {
      return allQuests.where((q) => q.safeForKids).toList();
    }
    return allQuests;
  }

  // Load quest progress from storage
  static Future<Map<String, QuestProgress>> loadProgress() async {
    final sp = await SharedPreferences.getInstance();
    final json = sp.getString(_progressKey);
    if (json == null) return {};

    final Map<String, dynamic> data = jsonDecode(json);
    return data.map((key, value) =>
        MapEntry(key, QuestProgress.fromJson(Map<String, dynamic>.from(value))));
  }

  // Save quest progress
  static Future<void> saveProgress(Map<String, QuestProgress> progress) async {
    final sp = await SharedPreferences.getInstance();
    final data = progress.map((key, value) => MapEntry(key, value.toJson()));
    await sp.setString(_progressKey, jsonEncode(data));
  }

  // Update progress based on a new capture
  static Future<List<Quest>> updateProgressForCapture(
    Capture capture,
    bool kidsMode,
  ) async {
    final progress = await loadProgress();
    final availableQuests = getAvailableQuests(kidsMode);
    final completedQuests = <Quest>[];

    // Load all captures to count unique groups for diversity quest
    final allCaptures = await _loadAllCaptures();

    for (final quest in availableQuests) {
      final questProgress = progress[quest.id] ??
          QuestProgress(questId: quest.id);

      if (questProgress.completed) continue;

      bool shouldIncrement = false;
      int? overrideCount;

      switch (quest.category) {
        case "collection":
          // Count all captures
          shouldIncrement = true;
          break;
        case "learning":
        case "exploration":
          // Check group match if specified
          if (quest.id == "diversity_junior") {
            // Special case: count unique groups
            // Note: Hard-coded quest ID is acceptable for MVP
            // Future: Add quest.needsUniqueGroupCount() or similar method
            final uniqueGroups = allCaptures.map((c) => c.group).toSet();
            overrideCount = uniqueGroups.length;
          } else if (quest.targetGroup != null) {
            shouldIncrement = capture.group == quest.targetGroup;
          } else if (quest.id == "state_species_hunter") {
            shouldIncrement = capture.flags["state_species"] == true;
          } else {
            shouldIncrement = true;
          }
          break;
      }

      if (overrideCount != null) {
        questProgress.currentCount = overrideCount;
      } else if (shouldIncrement) {
        questProgress.currentCount++;
      }
      
      if (questProgress.currentCount >= quest.targetCount) {
        questProgress.completed = true;
        questProgress.completedAt = DateTime.now();
        completedQuests.add(quest);
      }

      progress[quest.id] = questProgress;
    }

    await saveProgress(progress);
    return completedQuests;
  }

  // Helper to load all captures (avoids circular dependency)
  // Note: This duplicates JournalPage.loadCaptures() logic
  // Future: Extract to a shared CaptureService
  static Future<List<Capture>> _loadAllCaptures() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final txt = sp.getString("captures");
      if (txt == null) return [];
      final arr = jsonDecode(txt) as List<dynamic>;
      return arr.map((e) => Capture.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (e) {
      return [];
    }
  }

  // Get progress for a specific quest
  static Future<QuestProgress?> getQuestProgress(String questId) async {
    final progress = await loadProgress();
    return progress[questId];
  }

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
    
    // Calculate next Monday at 23:59:59 for weekly expiry
    int daysUntilMonday = (DateTime.monday - now.weekday) % 7;
    if (daysUntilMonday == 0) {
      // If today is Monday, expire next Monday (7 days from now)
      daysUntilMonday = 7;
    }
    final weeklyExpiry = DateTime(now.year, now.month, now.day + daysUntilMonday, 23, 59, 59);

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
            // For diversity quests, progress is the total count of unique groups
            // captured so far (from all historical captures)
            final newProgress = uniqueGroups.length;
            if (newProgress > quest.progress) {
              quest.progress = newProgress;
              progressMade = true;
            }
          } else {
            // For regular count quests, increment on any capture
            quest.progress++;
            progressMade = true;
          }
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
