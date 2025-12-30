import 'dart:math';
import '../models/genus_suggestion.dart';
import 'catalog_service.dart';

/// Genus-first Identification Service
/// 
/// This service provides on-device insect identification using a genus-first approach.
/// After a photo is captured, it returns 3-5 plausible genus suggestions that the user
/// can confirm or override. The user can then optionally specify the full species.
/// 
/// ## Current Implementation: Stub/Placeholder
/// 
/// The current implementation uses heuristic-based logic to generate genus suggestions:
/// - Location-based filtering (prefers state species in Georgia)
/// - Simple random selection from catalog
/// - Simulated confidence scores
/// 
/// ## Replacing with Real ML Model
/// 
/// To integrate a TFLite model or cloud-based classifier:
/// 
/// 1. **TFLite On-Device Model:**
///    - Add your `.tflite` model file to `assets/models/`
///    - Update `pubspec.yaml` to include the model asset
///    - Import `tflite_flutter` package (already in dependencies)
///    - Replace `_generateGenusStub()` with actual inference:
///      ```dart
///      final interpreter = await Interpreter.fromAsset('models/genus_classifier.tflite');
///      // Preprocess image
///      // Run inference
///      // Parse output to List<GenusSuggestion>
///      ```
/// 
/// 2. **Cloud Classifier Fallback:**
///    - Add cloud endpoint configuration
///    - Implement `_identifyViaCloud()` method using `http` package
///    - Add connectivity check before cloud call
///    - Fall back to on-device if offline
///    - Example structure:
///      ```dart
///      Future<List<GenusSuggestion>> _identifyViaCloud(String imagePath) async {
///        final bytes = await File(imagePath).readAsBytes();
///        final response = await http.post(
///          Uri.parse('https://your-api.com/identify'),
///          headers: {'Content-Type': 'application/octet-stream'},
///          body: bytes,
///        );
///        // Parse response JSON to List<GenusSuggestion>
///      }
///      ```
/// 
/// 3. **Hybrid Approach:**
///    - Try on-device inference first for speed
///    - If confidence is low (< 0.5), fall back to cloud
///    - Cache cloud results for offline use
/// 
/// ## Kids Mode Safety Filtering
/// 
/// The service automatically filters unsafe genera when Kids Mode is enabled:
/// - Spiders (Phidippus, Argiope, Trichonephila, etc.)
/// - Centipedes (Scutigera)
/// - Other potentially concerning arthropods
/// 
/// Update `_unsafeGeneraForKids` list to add/remove filtered genera.
class IdentifierService {
  final CatalogService catalogService;
  final Random _random = Random();

  /// List of genera that should be filtered out in Kids Mode
  /// 
  /// These are considered potentially scary or unsafe for young children.
  /// Update this list based on educational guidance and parent feedback.
  static const List<String> _unsafeGeneraForKids = [
    'Phidippus',      // Jumping spiders
    'Argiope',        // Garden spiders (orb weavers)
    'Trichonephila',  // Joro spiders
    'Scutigera',      // House centipedes
    // Add more genera as needed
  ];

  /// Groups that should be filtered in Kids Mode
  static const List<String> _unsafeGroupsForKids = [
    'Arachnids – Spiders',
    'Myriapods – Centipedes',
  ];

  IdentifierService({required this.catalogService});

  /// Identify genus from captured photo
  /// 
  /// Returns 3-5 plausible genus suggestions based on:
  /// - Image analysis (stub: heuristic, future: ML model)
  /// - Geographic location (prefers local species)
  /// - Kids Mode filtering (removes unsafe genera)
  /// 
  /// [imagePath] Path to captured photo
  /// [lat] Latitude of capture location
  /// [lon] Longitude of capture location
  /// [kidsMode] Whether Kids Mode is enabled (filters unsafe genera)
  /// 
  /// Returns list of 3-5 genus suggestions ordered by confidence (highest first)
  Future<List<GenusSuggestion>> identifyGenus({
    required String imagePath,
    required double lat,
    required double lon,
    required bool kidsMode,
  }) async {
    // TODO: Replace with actual ML inference
    // For now, use stub implementation
    List<GenusSuggestion> suggestions = await _generateGenusStub(lat, lon);

    // Apply Kids Mode filtering
    if (kidsMode) {
      suggestions = _filterForKidsMode(suggestions);
    }

    // Ensure we have 3-5 suggestions
    suggestions = suggestions.take(5).toList();
    if (suggestions.length < 3) {
      // Pad with additional safe suggestions if needed (avoiding duplicates)
      suggestions.addAll(_getAdditionalSafeSuggestions(suggestions, 3 - suggestions.length));
    }

    return suggestions;
  }

  /// Stub implementation that generates genus suggestions using heuristics
  /// 
  /// **REPLACE THIS METHOD** when integrating real ML model.
  /// 
  /// Current logic:
  /// - Prefers Georgia state species when in state
  /// - Randomly selects from catalog entries
  /// - Assigns simulated confidence scores
  Future<List<GenusSuggestion>> _generateGenusStub(double lat, double lon) async {
    final inGeorgia = lat >= 30 && lat <= 35 && lon <= -80 && lon >= -85;
    final suggestions = <GenusSuggestion>[];

    // Get all available genera from catalog
    final availableGenera = _extractGeneraFromCatalog();

    // Prefer state species if in Georgia
    if (inGeorgia) {
      final stateSpecies = catalogService.stateSpeciesGeorgia();
      for (final item in stateSpecies) {
        final entry = item["entry"];
        String genus = _extractGenus(entry);
        if (genus.isNotEmpty && !_hasGenus(suggestions, genus)) {
          suggestions.add(GenusSuggestion(
            genus: genus,
            confidence: 0.75 + _random.nextDouble() * 0.20, // 0.75-0.95
            commonName: entry["common"],
            group: item["group"],
          ));
        }
      }
    }

    // Add random genera from catalog to reach 3-5 suggestions
    final shuffledGenera = List.from(availableGenera)..shuffle(_random);
    for (final genusData in shuffledGenera) {
      if (suggestions.length >= 5) break;
      if (!_hasGenus(suggestions, genusData['genus'])) {
        suggestions.add(GenusSuggestion(
          genus: genusData['genus'],
          confidence: 0.50 + _random.nextDouble() * 0.35, // 0.50-0.85
          commonName: genusData['common'],
          group: genusData['group'],
        ));
      }
    }

    // Sort by confidence (descending)
    suggestions.sort((a, b) => b.confidence.compareTo(a.confidence));

    return suggestions;
  }

  /// Extract genus name from catalog entry
  String _extractGenus(Map<String, dynamic> entry) {
    // Try explicit genus field first
    String genus = entry["genus"] ?? "";
    
    // If no genus field, extract from species (first word)
    if (genus.isEmpty) {
      final species = entry["species"];
      if (species != null && species.isNotEmpty) {
        final parts = species.toString().trim().split(" ");
        if (parts.isNotEmpty && parts[0].isNotEmpty) {
          genus = parts[0];
        }
      }
    }
    
    return genus;
  }

  /// Extract all unique genera from catalog
  List<Map<String, dynamic>> _extractGeneraFromCatalog() {
    final generaMap = <String, Map<String, dynamic>>{};
    
    for (final group in catalogService.catalog["groups"]) {
      final groupName = group["group"];
      for (final entry in group["entries"]) {
        final genus = _extractGenus(entry);
        if (genus.isNotEmpty && !generaMap.containsKey(genus)) {
          generaMap[genus] = {
            'genus': genus,
            'common': entry["common"],
            'group': groupName,
          };
        }
      }
    }
    
    return generaMap.values.toList();
  }

  /// Check if suggestions already contains a genus
  bool _hasGenus(List<GenusSuggestion> suggestions, String genus) {
    return suggestions.any((s) => s.genus == genus);
  }

  /// Filter suggestions for Kids Mode
  /// 
  /// Removes genera and groups that are considered unsafe or scary for children.
  List<GenusSuggestion> _filterForKidsMode(List<GenusSuggestion> suggestions) {
    return suggestions.where((suggestion) {
      // Filter by genus name
      if (_unsafeGeneraForKids.contains(suggestion.genus)) {
        return false;
      }
      
      // Filter by group (null-safe)
      final group = suggestion.group;
      if (group != null) {
        if (_unsafeGroupsForKids.any((unsafe) => group.contains(unsafe))) {
          return false;
        }
      }
      
      return true;
    }).toList();
  }

  /// Get additional safe suggestions to ensure minimum count
  /// 
  /// Provides fallback genus suggestions that are safe for all users.
  /// Checks for duplicates by examining existing suggestions.
  /// 
  /// [existingSuggestions] Current list of suggestions to check for duplicates
  /// [needed] Number of additional suggestions needed
  List<GenusSuggestion> _getAdditionalSafeSuggestions(List<GenusSuggestion> existingSuggestions, int needed) {
    final existingGenera = existingSuggestions.map((s) => s.genus).toSet();
    
    final safeSuggestions = [
      GenusSuggestion(
        genus: 'Papilio',
        confidence: 0.45,
        commonName: 'Swallowtail Butterflies',
        group: 'Butterflies',
      ),
      GenusSuggestion(
        genus: 'Apis',
        confidence: 0.40,
        commonName: 'Honey Bees',
        group: 'Bees/Wasps',
      ),
      GenusSuggestion(
        genus: 'Bombus',
        confidence: 0.35,
        commonName: 'Bumblebees',
        group: 'Bees/Wasps',
      ),
      GenusSuggestion(
        genus: 'Danaus',
        confidence: 0.30,
        commonName: 'Monarchs',
        group: 'Butterflies',
      ),
    ];
    
    // Filter out duplicates and take only what's needed
    return safeSuggestions
        .where((s) => !existingGenera.contains(s.genus))
        .take(needed)
        .toList();
  }

  /// Get species suggestions for a confirmed genus
  /// 
  /// After user confirms a genus, this can provide species-level suggestions
  /// if available in the catalog.
  /// 
  /// [genus] The confirmed genus name
  /// Returns list of species names for that genus
  List<String> getSpeciesSuggestionsForGenus(String genus) {
    final species = <String>[];
    
    for (final group in catalogService.catalog["groups"]) {
      for (final entry in group["entries"]) {
        final entryGenus = _extractGenus(entry);
        final entrySpecies = entry["species"];
        
        if (entryGenus == genus && entrySpecies != null && entrySpecies.isNotEmpty) {
          species.add(entrySpecies);
        }
      }
    }
    
    return species;
  }
}
