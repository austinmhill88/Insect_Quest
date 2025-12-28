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
}