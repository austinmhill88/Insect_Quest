class Streak {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActivityDate;

  Streak({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastActivityDate,
  });

  Map<String, dynamic> toJson() => {
        "currentStreak": currentStreak,
        "longestStreak": longestStreak,
        "lastActivityDate": lastActivityDate?.toIso8601String(),
      };

  static Streak fromJson(Map<String, dynamic> m) => Streak(
        currentStreak: m["currentStreak"] ?? 0,
        longestStreak: m["longestStreak"] ?? 0,
        lastActivityDate: m["lastActivityDate"] != null
            ? DateTime.parse(m["lastActivityDate"])
            : null,
      );

  Streak copyWith({
    int? currentStreak,
    int? longestStreak,
    DateTime? lastActivityDate,
  }) {
    return Streak(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
    );
  }
}
