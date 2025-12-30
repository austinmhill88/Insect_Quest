class Scoring {
  static const base = {
    "Common": 50,
    "Uncommon": 75,
    "Rare": 120,
    "Epic": 180,
    "Legendary": 250,
  };

  static const mult = {
    "Common": 1.0,
    "Uncommon": 1.5,
    "Rare": 2.5,
    "Epic": 4.0,
    "Legendary": 6.0,
  };

  static double qualityMultiplier({
    required double sharpness,
    required double exposure,
    required double framing,
    bool kidsMode = false,
  }) {
    final q = (sharpness * 0.4) + (exposure * 0.2) + (framing * 0.4);
    double clamped = q.clamp(0.85, 1.15).toDouble();
    if (kidsMode && clamped < 0.9) clamped = 0.9;
    return clamped;
  }

  static int points({
    required String tier,
    required double qualityMult,
    bool speciesConfirmed = false,
    bool firstGenus = false,
  }) {
    final baseScore = base[tier] ?? 50;
    final rMult = mult[tier] ?? 1.0;
    double p = baseScore * rMult * qualityMult;
    if (speciesConfirmed) p *= 1.30;
    if (firstGenus) p *= 1.15;
    return p.round();
  }

  /// Calculate coins awarded for minting a card (capturing an insect).
  /// 
  /// Coins are based on rarity tier and photo quality:
  /// - Common: 50 base (42-57 after quality)
  /// - Uncommon: 112 base (95-129 after quality)
  /// - Rare: 300 base (255-345 after quality)
  /// - Epic: 720 base (612-828 after quality)
  /// - Legendary: 1500 base (1275-1725 after quality)
  /// 
  /// Quality multiplier ranges from 0.85x to 1.15x based on photo quality.
  /// Should be clamped to reasonable bounds (0-10,000) by caller.
  static int coins({
    required String tier,
    required double qualityMult,
  }) {
    final baseScore = base[tier] ?? 50;
    final rMult = mult[tier] ?? 1.0;
    double c = baseScore * rMult * qualityMult;
    return c.round();
  }
}