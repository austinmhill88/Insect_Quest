import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/arthropod_card.dart';

/// Service for managing ArthropodCard collection locally and with Firestore.
///
/// Handles card minting, storage, and retrieval. Uses SharedPreferences for
/// local storage (MVP) with Firestore integration ready for future use.
class CardService {
  static const String _cardsKey = "critter_codex_cards";

  /// Mint a new card from capture data
  ///
  /// This is the primary card creation method. It assigns rarity based on
  /// tier, determines foil status, and extracts traits from flags.
  static ArthropodCard mintCard({
    required String id,
    required String userId,
    required String genus,
    String? species,
    required String tier,
    required double quality,
    required DateTime timestamp,
    required String geocell,
    required String photoPath,
    required Map<String, bool> flags,
  }) {
    // Assign rarity based on tier
    final rarity = _assignRarity(tier, flags);

    // Extract traits from flags
    final traits = <String>[];
    flags.forEach((key, value) {
      if (value == true) {
        traits.add(key);
      }
    });

    // Determine foil status (rare chance for high-quality legendary captures)
    final foil = _shouldBeFoil(rarity, quality);

    return ArthropodCard(
      id: id,
      userId: userId,
      genus: genus,
      species: species,
      rarity: rarity,
      quality: quality,
      timestamp: timestamp,
      regionCell: geocell,
      imageUrl: photoPath,
      traits: traits,
      foil: foil,
    );
  }

  /// Assign rarity tier using heuristic
  ///
  /// Rarity is primarily based on the tier from catalog, with special handling
  /// for legendary state species and potential future override maps.
  static String _assignRarity(String tier, Map<String, bool> flags) {
    // Check for legendary override (state species)
    if (flags["state_species"] == true && tier == "Legendary") {
      return "Legendary";
    }

    // Map tier to rarity (they're mostly the same in MVP)
    switch (tier) {
      case "Legendary":
        return "Legendary";
      case "Epic":
        return "Epic";
      case "Rare":
        return "Rare";
      case "Uncommon":
        return "Uncommon";
      case "Common":
      default:
        return "Common";
    }
  }

  /// Determine if card should be foil variant
  ///
  /// Foil cards are special shiny variants with enhanced visual effects.
  /// Criteria: Legendary rarity + quality >= 1.05 (top ~5% of photos)
  static bool _shouldBeFoil(String rarity, double quality) {
    return rarity == "Legendary" && quality >= 1.05;
  }

  /// Save a card to local storage
  ///
  /// Cards are stored as JSON in SharedPreferences for MVP.
  /// Future: This will also save to Firestore.
  static Future<void> saveCard(ArthropodCard card) async {
    final cards = await loadCards();
    cards.add(card);
    
    final sp = await SharedPreferences.getInstance();
    final jsonList = cards.map((c) => c.toJson()).toList();
    await sp.setString(_cardsKey, jsonEncode(jsonList));
  }

  /// Load all cards from local storage
  ///
  /// Returns list of cards sorted by timestamp (newest first).
  static Future<List<ArthropodCard>> loadCards() async {
    final sp = await SharedPreferences.getInstance();
    final jsonStr = sp.getString(_cardsKey);
    
    if (jsonStr == null || jsonStr.isEmpty) {
      return [];
    }

    final jsonList = jsonDecode(jsonStr) as List<dynamic>;
    final cards = jsonList
        .map((json) => ArthropodCard.fromJson(Map<String, dynamic>.from(json)))
        .toList();
    
    // Sort by timestamp descending (newest first)
    cards.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    return cards;
  }

  /// Get card count by rarity
  ///
  /// Useful for collection statistics and achievements.
  static Future<Map<String, int>> getCardCountsByRarity() async {
    final cards = await loadCards();
    final counts = <String, int>{
      "Common": 0,
      "Uncommon": 0,
      "Rare": 0,
      "Epic": 0,
      "Legendary": 0,
    };

    for (final card in cards) {
      counts[card.rarity] = (counts[card.rarity] ?? 0) + 1;
    }

    return counts;
  }

  /// Get unique species count
  ///
  /// Counts distinct species in collection.
  static Future<int> getUniqueSpeciesCount() async {
    final cards = await loadCards();
    final species = cards
        .where((c) => c.species != null)
        .map((c) => c.species!)
        .toSet();
    return species.length;
  }

  /// Get unique genus count
  ///
  /// Counts distinct genera in collection.
  static Future<int> getUniqueGenusCount() async {
    final cards = await loadCards();
    final genera = cards.map((c) => c.genus).toSet();
    return genera.length;
  }

  // Future Firestore methods (stubs for now):
  
  /// Save card to Firestore (future implementation)
  ///
  /// Will upload card data to user's Firestore collection.
  /// Requires Firebase initialization and authentication.
  static Future<void> saveCardToFirestore(ArthropodCard card) async {
    // TODO: Implement Firestore save
    // final firestore = FirebaseFirestore.instance;
    // await firestore
    //     .collection('users')
    //     .doc(card.userId)
    //     .collection('cards')
    //     .doc(card.id)
    //     .set(card.toJson());
  }

  /// Load cards from Firestore (future implementation)
  ///
  /// Will sync cards from Firestore to local storage.
  static Future<List<ArthropodCard>> loadCardsFromFirestore(String userId) async {
    // TODO: Implement Firestore load
    // final firestore = FirebaseFirestore.instance;
    // final snapshot = await firestore
    //     .collection('users')
    //     .doc(userId)
    //     .collection('cards')
    //     .get();
    // return snapshot.docs
    //     .map((doc) => ArthropodCard.fromJson(doc.data()))
    //     .toList();
    return [];
  }
}
