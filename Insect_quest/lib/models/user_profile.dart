class UserProfile {
  final String userId;
  final int coins;
  final DateTime lastUpdated;

  UserProfile({
    required this.userId,
    required this.coins,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() => {
        "userId": userId,
        "coins": coins,
        "lastUpdated": lastUpdated.toIso8601String(),
      };

  static UserProfile fromJson(Map<String, dynamic> m) => UserProfile(
        userId: m["userId"],
        coins: m["coins"],
        lastUpdated: DateTime.parse(m["lastUpdated"]),
      );

  UserProfile copyWith({
    String? userId,
    int? coins,
    DateTime? lastUpdated,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      coins: coins ?? this.coins,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
