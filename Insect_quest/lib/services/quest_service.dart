import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quest.dart';
import '../models/capture.dart';

class QuestService {
  static const _progressKey = "quest_progress";

  // Predefined quests - safe quests are kid-friendly
  static final List<Quest> allQuests = [
    // Safe learning quests for kids
    const Quest(
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
    const Quest(
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
    const Quest(
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
    const Quest(
      id: "first_five",
      title: "First Five Friends",
      description: "Capture your first 5 insects! Great start!",
      category: "collection",
      targetCount: 5,
      safeForKids: true,
      rewardPoints: 150,
      emoji: "⭐",
    ),
    const Quest(
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
    const Quest(
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
    const Quest(
      id: "collector_pro",
      title: "Collector Pro",
      description: "Capture 20 total insects",
      category: "collection",
      targetCount: 20,
      safeForKids: false, // advanced goal
      rewardPoints: 300,
      emoji: "🏆",
    ),
    const Quest(
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
}
