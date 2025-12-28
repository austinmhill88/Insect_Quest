import 'dart:math';

class MLService {
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