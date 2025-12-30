class Capture {
  final String id;
  final String photoPath;
  final DateTime timestamp;
  final double lat; // Coarse latitude from geocell (0.01° precision)
  final double lon; // Coarse longitude from geocell (0.01° precision)
  final String geocell; // coarse location string (e.g., "34.00,-84.00")
  final String group;   // e.g., Butterflies
  final String genus;
  final String? species;
  final String tier;    // Common..Legendary
  final Map<String, bool> flags; // state_species, invasive, venomous
  final int points;
  final double quality;
  final int coins; // Coins awarded for this capture
  final String? validationStatus; // "valid", "flagged", "rejected"
  final String? photoHash; // perceptual hash for duplicate detection
  final bool hasExif; // whether photo has valid EXIF data
  final bool livenessVerified; // whether liveness check was passed

  Capture({
    required this.id,
    required this.photoPath,
    required this.timestamp,
    required this.lat,
    required this.lon,
    required this.geocell,
    required this.group,
    required this.genus,
    required this.species,
    required this.tier,
    required this.flags,
    required this.points,
    required this.quality,
    required this.coins,
    this.validationStatus,
    this.photoHash,
    this.hasExif = true,
    this.livenessVerified = false,
  });

  Map<String, dynamic> toJson() => {
        "id": id,
        "photoPath": photoPath,
        "timestamp": timestamp.toIso8601String(),
        "lat": lat,
        "lon": lon,
        "geocell": geocell,
        "group": group,
        "genus": genus,
        "species": species,
        "tier": tier,
        "flags": flags,
        "points": points,
        "quality": quality,
        "coins": coins,
        "validationStatus": validationStatus,
        "photoHash": photoHash,
        "hasExif": hasExif,
        "livenessVerified": livenessVerified,
      };

  static Capture fromJson(Map<String, dynamic> m) => Capture(
        id: m["id"],
        photoPath: m["photoPath"],
        timestamp: DateTime.parse(m["timestamp"]),
        lat: m["lat"],
        lon: m["lon"],
        geocell: m["geocell"],
        group: m["group"],
        genus: m["genus"],
        species: m["species"],
        tier: m["tier"],
        flags: Map<String, bool>.from(m["flags"] ?? {}),
        points: m["points"],
        quality: m["quality"],
        coins: m["coins"] ?? 0, // Default to 0 for backward compatibility
        validationStatus: m["validationStatus"],
        photoHash: m["photoHash"],
        hasExif: m["hasExif"] ?? true,
        livenessVerified: m["livenessVerified"] ?? false,
      );
}