/// Data model for a collectible Critter Codex card.
///
/// Each valid photo submission mints a unique card with taxonomic info,
/// rarity tier, quality score, and game attributes like traits and foil status.
/// This model supports both local storage and Firestore serialization.
class ArthropodCard {
  /// Unique card identifier (UUID v4)
  final String id;

  /// User identifier who captured this card
  final String userId;

  /// Taxonomic genus (always present)
  final String genus;

  /// Taxonomic species (optional, may be null for genus-only IDs)
  final String? species;

  /// Rarity tier: Common, Uncommon, Rare, Epic, or Legendary
  final String rarity;

  /// Quality score from photo analysis (0.0 to 1.0+ range)
  final double quality;

  /// Timestamp when the card was minted/captured
  final DateTime timestamp;

  /// Coarse location cell (~1km precision) for privacy, format: "lat,lon"
  final String regionCell;

  /// URL or path to the uploaded photo
  final String imageUrl;

  /// List of special traits or flags (e.g., "state_species", "invasive", "venomous")
  final List<String> traits;

  /// Whether this is a special foil/shiny variant
  final bool foil;

  ArthropodCard({
    required this.id,
    required this.userId,
    required this.genus,
    this.species,
    required this.rarity,
    required this.quality,
    required this.timestamp,
    required this.regionCell,
    required this.imageUrl,
    required this.traits,
    required this.foil,
  });

  /// Convert card to JSON/Firestore-compatible map
  Map<String, dynamic> toJson() => {
        "id": id,
        "userId": userId,
        "genus": genus,
        "species": species,
        "rarity": rarity,
        "quality": quality,
        "timestamp": timestamp.toIso8601String(),
        "regionCell": regionCell,
        "imageUrl": imageUrl,
        "traits": traits,
        "foil": foil,
      };

  /// Create card from JSON/Firestore map
  static ArthropodCard fromJson(Map<String, dynamic> json) => ArthropodCard(
        id: json["id"],
        userId: json["userId"],
        genus: json["genus"],
        species: json["species"],
        rarity: json["rarity"],
        quality: (json["quality"] as num).toDouble(),
        timestamp: DateTime.parse(json["timestamp"]),
        regionCell: json["regionCell"],
        imageUrl: json["imageUrl"],
        traits: List<String>.from(json["traits"] ?? []),
        foil: json["foil"] ?? false,
      );

  /// Create a display name for the card (species if available, otherwise genus)
  String get displayName => species ?? genus;

  /// Check if this card has a specific trait
  bool hasTrait(String trait) => traits.contains(trait);
}
