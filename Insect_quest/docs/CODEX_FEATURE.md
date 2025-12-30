# Critter Codex (Field Log) Feature

## Overview

The Critter Codex is a visual card collection interface that displays all captured insects and arthropods in a grid layout with advanced filtering capabilities. This feature transforms the capture history into an engaging collection experience similar to trading card games.

## Features Implemented

### 1. Grid Layout Display
- **Grid View**: 2-column responsive grid showing captured cards
- **Card Design**:
  - Photo thumbnail with gradient overlay for text visibility
  - Genus/species name prominently displayed
  - Group classification subtitle
  - Rarity badge (top-right corner with colored icon)
  - State species star badge (top-left corner for special species)
  - Points and quality percentage footer

### 2. Rarity System

Each card displays a rarity badge with distinctive colors and icons:

| Rarity    | Color  | Icon           | Base Points |
|-----------|--------|----------------|-------------|
| Common    | Grey   | Circle         | 50          |
| Uncommon  | Green  | Album          | 75          |
| Rare      | Blue   | Hexagon        | 120         |
| Epic      | Purple | Stars          | 180         |
| Legendary | Amber  | Auto Awesome   | 250         |

### 3. Filtering System

The Codex includes three filtering mechanisms:

#### a) Search Bar
- Real-time text search
- Searches both genus and species names
- Case-insensitive matching

#### b) Rarity Filter
- Filter by specific rarity tier
- Dialog selection with visual rarity indicators
- Shows all rarities present in collection

#### c) Genus Filter
- Filter by taxonomic genus
- Shows all unique genera in collection
- Alphabetically sorted list

#### d) Clear Filters
- Quick action chip to reset all filters
- Only appears when filters are active

### 4. Card Detail Page

Tapping any card opens a detailed view showing:

#### Hero Image Section
- Full-size photo with decorative rarity-colored border
- Large rarity badge overlay
- Responsive image container (300px height)

#### Stats Section
- **Points**: Total points awarded for the capture
- **Quality**: Photo quality percentage (0-115%)
- **Genus**: Scientific genus name
- **Species**: Scientific species name (if identified)

#### Location Section
- **Region**: Geographic region (North Georgia)
- **Geocell**: Coarse location identifier (~1km accuracy)
- **Coordinates**: Precise lat/lon (4 decimal places)

#### Collection Info Section
- **Collected**: Date and time of capture (formatted: "MMM d, yyyy at h:mm a")
- **Card ID**: First 8 characters of unique identifier

#### Traits Section
Visual badges for special characteristics:
- **State Species** (amber/star): Georgia state insect
- **Invasive** (orange/warning): Invasive species
- **Venomous** (red/health): Venomous species
- **Distinctive** (blue/visibility): Easily identifiable features

### 5. Navigation Integration

The Codex is integrated as the third tab in the bottom navigation:

```
[Camera] [Map] [Codex] [Journal]
   📷     🗺️     🎴      📚
```

### 6. State Management

#### Data Loading
- Loads captures from SharedPreferences on init
- Uses existing `JournalPage.loadCaptures()` method
- Consistent data source with Journal page

#### State Updates
- **Manual Refresh**: Refresh button in app bar
- **Pull-to-Refresh**: Swipe down gesture on grid
- **Keep Alive**: Uses `AutomaticKeepAliveClientMixin` to preserve scroll position and filters
- **Return from Detail**: Automatically refreshes when returning from card detail page

#### Filter State Persistence
- Filter selections preserved while navigating within Codex
- Filters maintained during page lifecycle
- Results count displayed above grid

### 7. Empty States

The Codex handles two empty states gracefully:

1. **No Captures**: Encourages users to capture critters
   - Pokémon ball icon
   - "No cards collected yet! Go capture some critters!" message

2. **No Matches**: When filters produce no results
   - Same icon
   - "No cards match your filters" message

### 8. Placeholder Assets

The implementation uses Flutter's built-in Material icons and colors as placeholders:

- **Card Frames**: Colored borders based on rarity
- **Rarity Badges**: Material icons (circle, album, hexagon, stars, auto_awesome)
- **Trait Icons**: Material icons (star, warning, health_and_safety, visibility)
- **Photos**: Displays actual captured photos with error fallback to bug icon

These can be easily replaced with custom assets by:
1. Adding image files to `assets/` directory
2. Updating `pubspec.yaml` to include asset paths
3. Replacing `Icon()` widgets with `Image.asset()` calls

## File Structure

```
lib/pages/
├── codex_page.dart       # Main grid view with filters
└── card_detail_page.dart # Full card details view
```

## Dependencies Added

```yaml
dependencies:
  intl: ^0.19.0  # For date formatting in detail view
```

## Usage Flow

1. **User captures an insect** using Camera tab
2. **Capture is saved** to SharedPreferences
3. **Navigate to Codex tab** to view collection
4. **Browse cards** in grid layout
5. **Apply filters** to find specific cards
6. **Tap a card** to view full details
7. **Return to grid** with filters preserved

## Technical Implementation Details

### Grid Configuration
```dart
GridView.builder(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,          // 2 columns
    childAspectRatio: 0.75,     // Vertical cards
    crossAxisSpacing: 8,        // Horizontal gap
    mainAxisSpacing: 8,         // Vertical gap
  ),
)
```

### Filter Logic
Filters are applied in sequence:
1. Check rarity match (if filter active)
2. Check genus match (if filter active)
3. Check search query in genus/species (if query present)

All conditions must pass for a card to appear.

### State Refresh
The Codex refreshes in three scenarios:
1. Initial load (`initState`)
2. Manual refresh (button or pull-to-refresh)
3. Return from detail page

## Future Enhancements

Potential improvements for post-MVP:

- [ ] Sort options (by date, points, rarity, genus)
- [ ] Set filters (group by collection sets or time periods)
- [ ] Animation when cards are added
- [ ] Statistics dashboard (collection completion %)
- [ ] Share card images
- [ ] Export collection as JSON
- [ ] Custom card frames based on achievements
- [ ] Animated rarity effects
- [ ] Collection milestones and badges
- [ ] Trading system integration
- [ ] Favorites marking

## Testing

To test the Codex feature:

1. **Capture some insects** using the Camera tab
2. **Navigate to Codex** tab (third icon in bottom nav)
3. **Verify grid displays** captured cards
4. **Test search** by typing genus/species names
5. **Test rarity filter** by selecting a rarity tier
6. **Test genus filter** by selecting a genus
7. **Tap a card** to view details
8. **Verify all card information** displays correctly
9. **Return to grid** and verify filters are preserved
10. **Test pull-to-refresh** gesture
11. **Test refresh button** in app bar

## Acceptance Criteria ✅

All acceptance criteria have been met:

- ✅ User browses, filters, and views detail on their cards in fully interactive UI
- ✅ UI uses placeholder art with easy asset swap (Material icons/colors)
- ✅ State updates when new cards are minted (refresh mechanisms in place)
- ✅ Grid display shows genus, rarity badge, and picture
- ✅ Filters by rarity, genus/species (stub traits/sets filters included in UI)
- ✅ Tapping card shows detail page with all required information

## Notes

- The implementation uses the existing `Capture` data model
- No database schema changes required
- Fully compatible with existing capture flow
- Zero breaking changes to existing features
- Ready for custom asset integration
