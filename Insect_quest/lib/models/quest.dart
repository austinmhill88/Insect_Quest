enum QuestType {
  captureAny,
  captureGroup,
  captureTier,
  captureSpecific,
  captureCount,
  captureQuality,
}

enum QuestPeriod {
  daily,
  weekly,
}

class Quest {
  final String id;
  final String title;
  final String description;
  final QuestType type;
  final QuestPeriod period;
  final Map<String, dynamic> requirements; // e.g., {"group": "Butterflies", "count": 3}
  final int coinReward;
  final bool foilReward;
  final DateTime expiresAt;
  int progress;
  int target;
  bool completed;
  bool claimed;

  Quest({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.period,
    required this.requirements,
    required this.coinReward,
    this.foilReward = false,
    required this.expiresAt,
    this.progress = 0,
    required this.target,
    this.completed = false,
    this.claimed = false,
  });

  Map<String, dynamic> toJson() => {
        "id": id,
        "title": title,
        "description": description,
        "type": type.name,
        "period": period.name,
        "requirements": requirements,
        "coinReward": coinReward,
        "foilReward": foilReward,
        "expiresAt": expiresAt.toIso8601String(),
        "progress": progress,
        "target": target,
        "completed": completed,
        "claimed": claimed,
      };

  static Quest fromJson(Map<String, dynamic> m) => Quest(
        id: m["id"],
        title: m["title"],
        description: m["description"],
        type: QuestType.values.firstWhere((e) => e.name == m["type"]),
        period: QuestPeriod.values.firstWhere((e) => e.name == m["period"]),
        requirements: Map<String, dynamic>.from(m["requirements"] ?? {}),
        coinReward: m["coinReward"],
        foilReward: m["foilReward"] ?? false,
        expiresAt: DateTime.parse(m["expiresAt"]),
        progress: m["progress"] ?? 0,
        target: m["target"],
        completed: m["completed"] ?? false,
        claimed: m["claimed"] ?? false,
      );

  Quest copyWith({
    int? progress,
    bool? completed,
    bool? claimed,
  }) {
    return Quest(
      id: id,
      title: title,
      description: description,
      type: type,
      period: period,
      requirements: requirements,
      coinReward: coinReward,
      foilReward: foilReward,
      expiresAt: expiresAt,
      progress: progress ?? this.progress,
      target: target,
      completed: completed ?? this.completed,
      claimed: claimed ?? this.claimed,
    );
  }
}
