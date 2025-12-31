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
  // Support both old and new quest systems
  final String? category; // "collection", "learning", "exploration" (old system)
  final int? targetCount; // old system
  final String? targetGroup; // null for any (old system)
  final bool safeForKids;
  final int? rewardPoints; // old system
  final String? emoji; // old system
  // New quest system fields
  final QuestType? type;
  final QuestPeriod? period;
  final Map<String, dynamic>? requirements;
  final int? coinReward;
  final bool? foilReward;
  final DateTime? expiresAt;
  int progress;
  int? target;
  bool completed;
  bool claimed;

  Quest({
    required this.id,
    required this.title,
    required this.description,
    this.category,
    this.targetCount,
    this.targetGroup,
    this.safeForKids = false,
    this.rewardPoints,
    this.emoji,
    this.type,
    this.period,
    this.requirements,
    this.coinReward,
    this.foilReward = false,
    this.expiresAt,
    this.progress = 0,
    this.target,
    this.completed = false,
    this.claimed = false,
  });

  const Quest.legacy({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.targetCount,
    this.targetGroup,
    required this.safeForKids,
    required this.rewardPoints,
    required this.emoji,
  })  : type = null,
        period = null,
        requirements = null,
        coinReward = null,
        foilReward = null,
        expiresAt = null,
        progress = 0,
        target = null,
        completed = false,
        claimed = false;

  Map<String, dynamic> toJson() {
    // Support both old and new quest formats
    if (type != null) {
      // New format
      return {
        "id": id,
        "title": title,
        "description": description,
        "type": type!.name,
        "period": period!.name,
        "requirements": requirements,
        "coinReward": coinReward,
        "foilReward": foilReward,
        "expiresAt": expiresAt?.toIso8601String(),
        "progress": progress,
        "target": target,
        "completed": completed,
        "claimed": claimed,
      };
    } else {
      // Old format (legacy)
      return {
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
    }
  }

  static Quest fromJson(Map<String, dynamic> json) {
    // Detect which format based on presence of 'type' field
    if (json.containsKey("type")) {
      // New format
      return Quest(
        id: json["id"],
        title: json["title"],
        description: json["description"],
        type: QuestType.values.firstWhere((e) => e.name == json["type"]),
        period: QuestPeriod.values.firstWhere((e) => e.name == json["period"]),
        requirements: Map<String, dynamic>.from(json["requirements"] ?? {}),
        coinReward: json["coinReward"],
        foilReward: json["foilReward"] ?? false,
        expiresAt: DateTime.parse(json["expiresAt"]),
        progress: json["progress"] ?? 0,
        target: json["target"],
        completed: json["completed"] ?? false,
        claimed: json["claimed"] ?? false,
      );
    } else {
      // Old format (legacy)
      return Quest(
        id: json["id"],
        title: json["title"],
        description: json["description"],
        category: json["category"],
        targetCount: json["targetCount"],
        targetGroup: json["targetGroup"],
        safeForKids: json["safeForKids"] ?? false,
        rewardPoints: json["rewardPoints"],
        emoji: json["emoji"],
      );
    }
  }

  Quest copyWith({
    int? progress,
    bool? completed,
    bool? claimed,
  }) {
    return Quest(
      id: id,
      title: title,
      description: description,
      category: category,
      targetCount: targetCount,
      targetGroup: targetGroup,
      safeForKids: safeForKids,
      rewardPoints: rewardPoints,
      emoji: emoji,
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
