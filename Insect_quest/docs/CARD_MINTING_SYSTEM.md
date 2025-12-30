# Card Minting System Documentation

## Overview

The Card Minting System transforms InsectQuest into a fully gamified experience by minting collectible cards for each valid photo submission. Each card is a unique digital collectible with rarity tiers, quality scores, and special attributes.

## Architecture

### Data Model: `ArthropodCard`

Located in `lib/models/arthropod_card.dart`

#### Fields

| Field | Type | Description |
|-------|------|-------------|
| `id` | String | Unique card identifier (UUID v4) |
| `userId` | String | User who captured this card |
| `genus` | String | Taxonomic genus (always present) |
| `species` | String? | Taxonomic species (optional) |
| `rarity` | String | Common, Uncommon, Rare, Epic, or Legendary |
| `quality` | double | Photo quality score (0.0 to 1.0+) |
| `timestamp` | DateTime | When the card was minted |
| `regionCell` | String | Coarse location (~1km precision) |
| `imageUrl` | String | Path to captured photo |
| `traits` | List<String> | Special traits (state_species, invasive, venomous) |
| `foil` | bool | Whether this is a special foil variant |

#### JSON Serialization

Supports both local storage (SharedPreferences) and Firestore:

```dart
// Convert to JSON
Map<String, dynamic> json = card.toJson();

// Create from JSON
ArthropodCard card = ArthropodCard.fromJson(json);
```

### Service: `CardService`

Located in `lib/services/card_service.dart`

#### Primary Methods

##### `mintCard()`
Mints a new card from capture data. This is the main entry point for card creation.

```dart
ArthropodCard card = CardService.mintCard(
  id: captureId,
  userId: "user123",
  genus: "Papilio",
  species: "Papilio glaucus",
  tier: "Legendary",
  quality: 1.05,
  timestamp: DateTime.now(),
  geocell: "34.00,-84.00",
  photoPath: "/path/to/photo.jpg",
  flags: {"state_species": true},
);
```

##### `saveCard()` / `loadCards()`
Local storage operations using SharedPreferences:

```dart
// Save a card
await CardService.saveCard(card);

// Load all cards (sorted by timestamp, newest first)
List<ArthropodCard> cards = await CardService.loadCards();
```

##### Statistics Methods
```dart
// Get card counts by rarity
Map<String, int> counts = await CardService.getCardCountsByRarity();

// Get unique species/genus counts
int speciesCount = await CardService.getUniqueSpeciesCount();
int genusCount = await CardService.getUniqueGenusCount();
```

### Widget: `CardRenderer`

Located in `lib/widgets/card_renderer.dart`

Renders an ArthropodCard with visual flair:

```dart
CardRenderer(
  card: myCard,
  showDetails: true, // Set to false for compact view
)
```

**Visual Features:**
- Placeholder frame background
- Captured photo with border
- Rarity-coded colors and icons
- Quality score display
- Trait badges with icons
- Foil overlay effect (for foil cards)
- Timestamp

### Page: `CritterCodexPage`

Located in `lib/pages/critter_codex_page.dart`

Displays the user's card collection with:
- Collection statistics (total cards, unique species/genera)
- Rarity distribution chart
- Scrollable grid of cards
- Tap to view card details
- Pull-to-refresh

## Rarity System

### Assignment Heuristic

Rarity is determined by the `tier` field from the species catalog:

| Tier | Rarity | Base Points | Multiplier |
|------|--------|-------------|------------|
| Common | Common | 50 | 1.0x |
| Uncommon | Uncommon | 75 | 1.5x |
| Rare | Rare | 120 | 2.5x |
| Epic | Epic | 180 | 4.0x |
| Legendary | Legendary | 250 | 6.0x |

### Special Cases

**State Species Override:**
- Georgia State Species (Eastern Tiger Swallowtail, Honey Bee) with `state_species: true` flag
- Always assigned Legendary rarity when tier is Legendary

**Future Override Maps:**
The system is designed to support additional override logic through configuration maps.

## Foil Cards

Foil cards are special shiny variants with enhanced visual effects.

**Criteria:**
- Rarity = Legendary
- Quality >= 1.05 (top ~5% of photos)

**Visual Effects:**
- Diagonal gradient overlay
- Glowing "FOIL" badge
- Enhanced color depth

## Traits System

Traits are extracted from the `flags` field of captures:

| Trait | Icon | Color | Description |
|-------|------|-------|-------------|
| `state_species` | ⭐ Star | Amber | State-designated species |
| `invasive` | ⚠️ Warning | Orange | Invasive species |
| `venomous` | 🛡️ Shield | Red | Potentially dangerous |

Traits appear as compact chips on the card display.

## Integration with Capture Flow

When a photo is captured (in `camera_page.dart`):

1. Photo quality is analyzed (sharpness, exposure, framing)
2. Species/genus is identified
3. A `Capture` object is created (existing system)
4. **New:** A `ArthropodCard` is minted via `CardService.mintCard()`
5. Both capture and card are saved
6. User sees: "Saved capture (+XXX pts) • [Rarity] card minted!"

```dart
// In camera_page.dart _capture() method
final card = CardService.mintCard(
  id: captureId,
  userId: "local_user",
  genus: genus,
  species: species,
  tier: tier,
  quality: qMult,
  timestamp: captureTimestamp,
  geocell: geocell,
  photoPath: file.path,
  flags: flags,
);

await CardService.saveCard(card);
```

## Assets

### Placeholder Card Frame

**Location:** `assets/images/cards/card_frame_placeholder.png`

**Specifications:**
- Dimensions: 400x600 pixels (2:3 aspect ratio)
- Format: PNG with transparency support
- Design: Forest green base with golden borders

**Replacement:**
To use custom artwork, simply replace this file with your own design. The CardRenderer will automatically use the new frame. Maintain the 2:3 aspect ratio for best results.

## Firebase/Firestore Integration

### Current State (MVP)
- Cards stored locally in SharedPreferences
- JSON format for easy migration to Firestore

### Future Implementation

Stub methods are provided in `CardService`:

```dart
// Save to Firestore
await CardService.saveCardToFirestore(card);

// Load from Firestore
List<ArthropodCard> cards = await CardService.loadCardsFromFirestore(userId);
```

**Required Setup:**
1. Add Firebase configuration to `android/app/google-services.json`
2. Initialize Firebase in `main.dart`:
   ```dart
   await Firebase.initializeApp();
   ```
3. Implement Firestore save/load methods in `CardService`

**Firestore Structure:**
```
/users/{userId}/cards/{cardId}
  ├─ id: "uuid"
  ├─ genus: "Papilio"
  ├─ species: "Papilio glaucus"
  ├─ rarity: "Legendary"
  ├─ quality: 1.05
  ├─ timestamp: "2024-12-30T12:00:00.000Z"
  ├─ regionCell: "34.00,-84.00"
  ├─ imageUrl: "gs://bucket/photos/uuid.jpg"
  ├─ traits: ["state_species"]
  └─ foil: true
```

## Navigation

The app now has 4 tabs:
1. **Capture** - Camera page for taking photos
2. **Map** - View capture locations
3. **Journal** - List of captures (existing)
4. **Codex** - Collection of minted cards (NEW)

## Dependencies

Added to `pubspec.yaml`:
```yaml
dependencies:
  cloud_firestore: ^5.4.4
  firebase_core: ^3.6.0
```

These are included for future Firestore integration but not yet initialized in the MVP.

## Testing the System

### Manual Testing Steps

1. **Launch the app**
   ```bash
   flutter run
   ```

2. **Capture a photo**
   - Navigate to Capture tab
   - Take a photo of an insect
   - Confirm quality and species

3. **Verify card minting**
   - Check for success message: "Saved capture (+XXX pts) • [Rarity] card minted!"
   - Navigate to Codex tab

4. **View collection**
   - See card in grid view
   - Check statistics update
   - Tap card for detail view

5. **Check edge cases**
   - Genus-only ID (no species)
   - State species (should be Legendary)
   - High quality photo (check for foil)
   - Various traits (state_species, invasive, venomous)

### Debug Output

Card minting produces debug logs:
```
Card minted: rarity=Legendary foil=true traits=[state_species]
```

## Code Quality

All code includes:
- ✅ Comprehensive class-level documentation
- ✅ Method-level documentation with parameters
- ✅ Inline comments for complex logic
- ✅ Type safety throughout
- ✅ Error handling (image loading, JSON parsing)
- ✅ Null safety annotations

## Future Enhancements

### Planned Features
- [ ] Firebase/Firestore cloud sync
- [ ] User authentication
- [ ] Trading system between users
- [ ] Card evolution/upgrades
- [ ] Achievement badges for collections
- [ ] Rarity animations on mint
- [ ] Card pack opening experience
- [ ] Leaderboards for rarest collections

### Art Replacement
- [ ] Commission custom card frames
- [ ] Create rarity-specific frames
- [ ] Add animated backgrounds
- [ ] Design special edition frames

### Game Mechanics
- [ ] Duplicate card management
- [ ] Card favoriting/starring
- [ ] Collection milestones
- [ ] Regional variant tracking

## Troubleshooting

### Cards not appearing in Codex
- Check that `CardService.saveCard()` is called after minting
- Verify SharedPreferences is not full
- Look for errors in debug logs

### Card images not loading
- Ensure photo path is valid and accessible
- Check file permissions
- Verify image file wasn't deleted

### Foil cards not showing overlay
- Confirm card.foil == true
- Check quality >= 1.05
- Verify rarity == "Legendary"

### Missing placeholder frame
- Ensure `assets/images/cards/card_frame_placeholder.png` exists
- Check `pubspec.yaml` includes asset path
- Run `flutter pub get` after modifying pubspec

## Summary

The Card Minting System successfully gamifies InsectQuest by:
- ✅ Minting unique collectible cards for each capture
- ✅ Implementing rarity-based progression
- ✅ Providing visual polish with placeholder frames
- ✅ Supporting future Firestore integration
- ✅ Creating engaging collection mechanics
- ✅ Maintaining complete documentation

All acceptance criteria from the issue are met:
- ✅ Data model with all required fields
- ✅ Firestore-compatible JSON serialization
- ✅ Placeholder card frame asset
- ✅ Rarity assignment heuristic
- ✅ Card renderer with placeholder frame
- ✅ Firestore save logic (stubbed for future)
- ✅ Critter Codex UI shows minted cards
- ✅ Cards have correct fields and use placeholder frame
- ✅ Easy art replacement via asset swap
- ✅ Comprehensive documentation
