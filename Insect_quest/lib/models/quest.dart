class Quest {
  final String id;
  final String title;
  final String description;
  final String category; // "collection", "learning", "exploration"
  final int targetCount;
  final String? targetGroup; // null for any
  final bool safeForKids;
  final int rewardPoints;
  final String emoji;

  const Quest({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.targetCount,
    this.targetGroup,
    required this.safeForKids,
    required this.rewardPoints,
    required this.emoji,
  });

  Map<String, dynamic> toJson() => {
        "id": id,
        "title": title,
        "description": description,
        "category": category,
        "targetCount": targetCount,
        "targetGroup": targetGroup,
        "safeForKids": safeForKids,
        "rewardPoints": rewardPoints,
        "emoji": emoji,
      };

  static Quest fromJson(Map<String, dynamic> json) => Quest(
        id: json["id"],
        title: json["title"],
        description: json["description"],
        category: json["category"],
        targetCount: json["targetCount"],
        targetGroup: json["targetGroup"],
        safeForKids: json["safeForKids"],
        rewardPoints: json["rewardPoints"],
        emoji: json["emoji"],
      );
}

class QuestProgress {
  final String questId;
  int currentCount;
  bool completed;
  DateTime? completedAt;

  QuestProgress({
    required this.questId,
    this.currentCount = 0,
    this.completed = false,
    this.completedAt,
  });

  Map<String, dynamic> toJson() => {
        "questId": questId,
        "currentCount": currentCount,
        "completed": completed,
        "completedAt": completedAt?.toIso8601String(),
      };

  static QuestProgress fromJson(Map<String, dynamic> json) => QuestProgress(
        questId: json["questId"],
        currentCount: json["currentCount"] ?? 0,
        completed: json["completed"] ?? false,
        completedAt: json["completedAt"] != null
            ? DateTime.parse(json["completedAt"])
            : null,
      );
}
