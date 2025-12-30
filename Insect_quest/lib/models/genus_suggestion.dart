/// Model for genus identification suggestions
/// 
/// Represents a single genus suggestion from the identification service.
/// Used in the genus-first identification flow where the ML model suggests
/// plausible genera before the user optionally specifies species.
class GenusSuggestion {
  /// Scientific genus name (e.g., "Papilio", "Apis", "Bombus")
  final String genus;
  
  /// Confidence score from ML model (0.0 to 1.0)
  /// 
  /// For stub implementation, this is a heuristic-based confidence.
  /// Real ML model should populate with actual inference confidence.
  final double confidence;
  
  /// Common name for the genus (e.g., "Swallowtail Butterflies", "Honey Bees")
  final String? commonName;
  
  /// Taxonomic group (e.g., "Butterflies", "Bees/Wasps")
  /// Used for display and filtering
  final String? group;

  GenusSuggestion({
    required this.genus,
    required this.confidence,
    this.commonName,
    this.group,
  });

  Map<String, dynamic> toJson() => {
        "genus": genus,
        "confidence": confidence,
        "commonName": commonName,
        "group": group,
      };

  static GenusSuggestion fromJson(Map<String, dynamic> json) => GenusSuggestion(
        genus: json["genus"],
        confidence: json["confidence"],
        commonName: json["commonName"],
        group: json["group"],
      );
}
