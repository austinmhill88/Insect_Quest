import 'dart:math';
import 'catalog_service.dart';

class MLService {
  final CatalogService? catalogService;
  
  MLService({this.catalogService});

  // Very simple heuristic-based stub for MVP
  Future<Map<String, dynamic>> analyze({
    required String imagePath,
    required double lat,
    required double lon,
  }) async {
    // Stub heuristics: random confidence, prefer butterflies if near GA
    final inGeorgia = lat >= 30 && lat <= 35 && lon <= -80 && lon >= -85;
    final rnd = Random();
    final confidence = 0.65 + rnd.nextDouble() * 0.3;
    final isButterfly = rnd.nextBool();

    // Task 6: Prefer state species for suggestions when in Georgia
    if (inGeorgia && catalogService != null) {
      final stateSpecies = catalogService!.stateSpeciesGeorgia();
      if (stateSpecies.isNotEmpty) {
        // Pick a state species to suggest
        final chosen = stateSpecies[rnd.nextInt(stateSpecies.length)];
        final entry = chosen["entry"];
        final species = entry["species"];
        String genus = entry["genus"] ?? "";
        
        // Extract genus from species if not explicitly provided
        if (genus.isEmpty && species != null && species.isNotEmpty) {
          final trimmed = species.trim();
          if (trimmed.isNotEmpty) {
            final parts = trimmed.split(" ");
            if (parts.isNotEmpty && parts[0].isNotEmpty) {
              genus = parts[0];
            } else {
              genus = "Unknown";
            }
          } else {
            genus = "Unknown";
          }
        }
        
        final isLepidoptera = chosen["group"] == "Butterflies";
        
        return {
          "order": isLepidoptera ? "Lepidoptera" : "Hymenoptera",
          "family": isLepidoptera ? "Papilionidae" : "Apidae",
          "genus": genus,
          "species_candidates": species != null
              ? [
                  {"species": species, "confidence": confidence}
                ]
              : [],
          "confidence": confidence
        };
      }
    }

    // Fallback to original heuristic
    final genus = isButterfly ? "Papilio" : "Apis";
    final speciesCandidates = isButterfly
        ? [
            {"species": "Papilio glaucus", "confidence": confidence},
            {"species": "Papilio troilus", "confidence": (confidence * 0.2)}
          ]
        : [
            {"species": "Apis mellifera", "confidence": confidence}
          ];

    return {
      "order": isButterfly ? "Lepidoptera" : "Hymenoptera",
      "family": isButterfly ? "Papilionidae" : "Apidae",
      "genus": genus,
      "species_candidates": speciesCandidates,
      "confidence": confidence
    };
  }
}