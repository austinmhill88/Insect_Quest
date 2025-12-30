enum AchievementType {
  setCompletion,
  regionCompletion,
  habitatCompletion,
  milestone,
  streak,
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final AchievementType type;
  final Map<String, dynamic> criteria; // e.g., {"group": "Butterflies", "complete": true}
  final int coinReward;
  bool unlocked;
  DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.criteria,
    this.coinReward = 0,
    this.unlocked = false,
    this.unlockedAt,
  });

  Map<String, dynamic> toJson() => {
        "id": id,
        "title": title,
        "description": description,
        "type": type.name,
        "criteria": criteria,
        "coinReward": coinReward,
        "unlocked": unlocked,
        "unlockedAt": unlockedAt?.toIso8601String(),
      };

  static Achievement fromJson(Map<String, dynamic> m) => Achievement(
        id: m["id"],
        title: m["title"],
        description: m["description"],
        type: AchievementType.values.firstWhere((e) => e.name == m["type"]),
        criteria: Map<String, dynamic>.from(m["criteria"] ?? {}),
        coinReward: m["coinReward"] ?? 0,
        unlocked: m["unlocked"] ?? false,
        unlockedAt: m["unlockedAt"] != null
            ? DateTime.parse(m["unlockedAt"])
            : null,
      );

  Achievement copyWith({
    bool? unlocked,
    DateTime? unlockedAt,
  }) {
    return Achievement(
      id: id,
      title: title,
      description: description,
      type: type,
      criteria: criteria,
      coinReward: coinReward,
      unlocked: unlocked ?? this.unlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }
}
