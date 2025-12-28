class Capture {
  final String id;
  final String photoPath;
  final DateTime timestamp;
  final double lat;
  final double lon;
  final String geocell; // coarse location string
  final String group;   // e.g., Butterflies
  final String genus;
  final String? species;
  final String tier;    // Common..Legendary
  final Map<String, bool> flags; // state_species, invasive, venomous
  final int points;
  final double quality;

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
      );
}