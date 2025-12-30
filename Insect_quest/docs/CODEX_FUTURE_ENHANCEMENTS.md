# Critter Codex - Future Enhancements

This document tracks potential improvements to the Critter Codex feature for future iterations.

## Code Quality Improvements

### 1. Rarity Tier Constants
**Current State:** Rarity tiers are hardcoded strings ("Common", "Uncommon", etc.)
**Suggested Improvement:** Create constants in RarityUtils
```dart
class RarityUtils {
  static const String commonTier = 'Common';
  static const String uncommonTier = 'Uncommon';
  static const String rareTier = 'Rare';
  static const String epicTier = 'Epic';
  static const String legendaryTier = 'Legendary';
  // ... existing methods
}
```
**Benefits:** Prevents typos, improves maintainability, enables IDE autocomplete

### 2. Capture Data Service
**Current State:** CodexPage directly calls `JournalPage.loadCaptures()`
**Suggested Improvement:** Create a dedicated `CaptureService` or `CaptureRepository`
```dart
class CaptureService {
  static Future<List<Capture>> loadCaptures() async { ... }
  static Future<void> saveCapture(Capture capture) async { ... }
  static Future<void> deleteCapture(String id) async { ... }
}
```
**Benefits:** Separation of concerns, easier testing, better code organization

### 3. Quality Percentage Helper
**Current State:** Quality calculation `(capture.quality * 100).toStringAsFixed(0)` is duplicated
**Suggested Improvement:** Add computed property to Capture model
```dart
class Capture {
  // ... existing fields
  
  String get qualityPercentage => '${(quality * 100).toStringAsFixed(0)}%';
  int get qualityScore => (quality * 100).toInt();
}
```
**Benefits:** DRY principle, consistent formatting, easier to update

### 4. Configurable Region
**Current State:** "North Georgia" is hardcoded in CardDetailPage
**Suggested Improvement:** Add region to Capture model or make it configurable
```dart
// Option 1: Add to Capture model
class Capture {
  final String region;
  // ...
}

// Option 2: Use catalog service
class CatalogService {
  String getRegionName() => catalog["region"] ?? "Unknown";
}
```
**Benefits:** Supports multiple regions, more flexible, data-driven

## Feature Enhancements

### Sort Options
- Sort by date (newest/oldest)
- Sort by points (highest/lowest)
- Sort by rarity (Legendary first/Common first)
- Sort by genus (alphabetical)
- Save sort preference

### Advanced Filters
- **Set Filters**: Group by collection date ranges (This week, This month, etc.)
- **Trait Filters**: Filter by invasive, venomous, state species
- **Group Filter**: Filter by taxonomic group (Butterflies, Bees, etc.)
- **Quality Filter**: Filter by quality ranges (>100%, 90-100%, etc.)
- **Multi-select Filters**: Select multiple rarities or genera at once

### Visual Enhancements
- **Card Animations**: Flip animation when opening detail view
- **Rarity Effects**: Particle effects or glow for Legendary cards
- **New Card Badge**: "NEW" badge on recently captured cards
- **Duplicate Indicator**: Show count if multiple captures of same species

### Statistics Dashboard
- Total cards collected
- Collection completion percentage per group
- Average quality score
- Rarest card in collection
- Most captured genus/species
- Points breakdown by rarity

### Collection Management
- **Favorites**: Mark favorite cards with a star
- **Hide/Archive**: Hide cards from main view
- **Bulk Actions**: Select multiple cards for batch operations
- **Export**: Export collection as JSON or image gallery
- **Share**: Share individual cards as images on social media

### Search Improvements
- **Advanced Search**: Search by common name, flags, or date range
- **Search History**: Recent searches dropdown
- **Search Suggestions**: Autocomplete based on captured genera/species
- **Voice Search**: Speak genus/species name

### Performance Optimizations
- **Pagination**: Load cards in batches for large collections
- **Image Thumbnails**: Generate and cache smaller thumbnails
- **Lazy Loading**: Load images only when visible
- **Background Sync**: Update collection in background

### Accessibility
- **Screen Reader Support**: Add semantic labels to all interactive elements
- **High Contrast Mode**: Alternative color schemes
- **Text Scaling**: Support for larger text sizes
- **Keyboard Navigation**: Full keyboard support for filters and navigation

### Integration Features
- **Trading System**: Mark cards as "available for trade"
- **Achievements**: Unlock badges for collection milestones
- **Challenges**: Complete collection challenges (e.g., "Collect all Legendary butterflies")
- **Social**: View friends' collections and compare stats

## Technical Debt

### Testing
- Unit tests for filter logic
- Widget tests for UI components
- Integration tests for data persistence
- Performance tests for large collections

### Error Handling
- Better error messages when images fail to load
- Retry mechanism for failed image loads
- Graceful degradation when storage is full
- Network error handling (for future server sync)

### Code Organization
- Extract filter logic to separate class
- Create reusable card widget component
- Standardize spacing and sizing constants
- Add theme-based color management

## Priority Ranking

**High Priority (Next Iteration):**
1. Rarity tier constants
2. Capture data service
3. Quality percentage helper
4. Sort options

**Medium Priority:**
5. Advanced filters (traits, group)
6. Statistics dashboard
7. Favorites feature
8. Search improvements

**Low Priority (Future):**
9. Configurable region
10. Visual enhancements
11. Integration features
12. Accessibility improvements

## Notes

- All suggestions are optional and do not affect current functionality
- MVP implementation is complete and meets all acceptance criteria
- Prioritize based on user feedback and business requirements
- Consider performance impact before adding new features
