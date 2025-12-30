# Critter Codex UI Visual Reference

This document provides a textual description of the Codex UI layouts for reference.

## Grid View Layout

```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃         Critter Codex            🔄      ┃  <- App Bar with refresh button
┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
┃ 🔍 Search genus or species              ┃  <- Search bar
┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
┃ [All Rarities ▼] [All Genera ▼] [Clear]┃  <- Filter chips (scrollable)
┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
┃ Showing 8 of 10 cards                    ┃  <- Results count
┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
┃                                          ┃
┃  ┌────────────┐    ┌────────────┐       ┃
┃  │  ⭐      🟡 │    │  ⭐      🟢 │       ┃  <- Special badge + Rarity badge
┃  │            │    │            │       ┃
┃  │   [Photo]  │    │   [Photo]  │       ┃
┃  │            │    │            │       ┃
┃  │════════════│    │════════════│       ┃
┃  │Papilio     │    │Bombus      │       ┃  <- Genus/Species
┃  │Butterflies │    │Bees/Wasps  │       ┃  <- Group
┃  ├────────────┤    ├────────────┤       ┃
┃  │250pts Q:98%│    │75pts Q:102%│       ┃  <- Points + Quality
┃  └────────────┘    └────────────┘       ┃
┃                                          ┃
┃  ┌────────────┐    ┌────────────┐       ┃
┃  │        🔵  │    │        🟣  │       ┃
┃  │            │    │            │       ┃
┃  │   [Photo]  │    │   [Photo]  │       ┃
┃  │            │    │            │       ┃
┃  │════════════│    │════════════│       ┃
┃  │Argiope     │    │Dynastes    │       ┃
┃  │Arachnids   │    │Beetles     │       ┃
┃  ├────────────┤    ├────────────┤       ┃
┃  │120pts Q:95%│    │180pts Q:107│       ┃
┃  └────────────┘    └────────────┘       ┃
┃                                          ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```

### Rarity Color Coding
- 🟡 Legendary (Amber/Gold)
- 🟣 Epic (Purple)
- 🔵 Rare (Blue)
- 🟢 Uncommon (Green)
- ⚫ Common (Grey)

### Special Badges
- ⭐ State Species (Amber star)
- ⚠️ Invasive (Orange warning)
- 🏥 Venomous (Red health icon)

## Card Detail View Layout

```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃ ← Card Details                          ┃  <- App Bar with back button
┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
┃ ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓  ┃
┃ ┃                              🟡 ⭐  ┃  ┃  <- Hero Image with border
┃ ┃                            LEGENDARY┃  ┃     and rarity badge
┃ ┃                                     ┃  ┃
┃ ┃         [Large Photo]               ┃  ┃
┃ ┃                                     ┃  ┃
┃ ┃                                     ┃  ┃
┃ ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛  ┃
┃                                          ┃
┃     Papilio glaucus                      ┃  <- Species name (bold, colored)
┃     Butterflies                          ┃  <- Group
┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
┃  Stats                                   ┃
┃  Points         250                      ┃
┃  Quality        98.5%                    ┃
┃  Genus          Papilio                  ┃
┃  Species        Papilio glaucus          ┃
┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
┃  Location                                ┃
┃  Region         North Georgia            ┃
┃  Geocell        34.00,-84.00             ┃
┃  Coordinates    34.1234, -84.5678        ┃
┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
┃  Collection Info                         ┃
┃  Collected      Dec 30, 2025 at 3:45 PM  ┃
┃  Card ID        a1b2c3d4                 ┃
┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
┃  Traits                                  ┃
┃  [⭐ State Species] [👁️ Distinctive]     ┃  <- Trait chips
┃                                          ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```

## Filter Dialog Examples

### Rarity Filter Dialog
```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃ Filter by Rarity          ┃
┣━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
┃ ○ All                     ┃
┃ 🟡 ⭐ Legendary            ┃
┃ 🟣 ✦ Epic                 ┃
┃ 🔵 ⬡ Rare                 ┃
┃ 🟢 ◉ Uncommon             ┃
┃ ⚫ ● Common               ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```

### Genus Filter Dialog
```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃ Filter by Genus           ┃
┣━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
┃ ○ All                     ┃
┃ ○ Apis                    ┃
┃ ○ Argiope                 ┃
┃ ○ Bombus                  ┃
┃ ○ Danaus                  ┃
┃ ○ Dynastes                ┃
┃ ○ Papilio                 ┃
┃ ○ Phidippus               ┃
┃   ...                     ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```

## Empty States

### No Captures Yet
```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃         Critter Codex            🔄      ┃
┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
┃ 🔍 Search genus or species              ┃
┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
┃ [All Rarities ▼] [All Genera ▼]         ┃
┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
┃ Showing 0 of 0 cards                     ┃
┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
┃                                          ┃
┃              🎯                          ┃  <- Pokéball icon
┃                                          ┃
┃      No cards collected yet!             ┃
┃   Go capture some critters!              ┃
┃                                          ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```

### No Matches for Filters
```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃         Critter Codex            🔄      ┃
┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
┃ 🔍 "Monarchs"                            ┃
┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
┃ [Legendary ▼] [All Genera ▼] [Clear]    ┃
┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
┃ Showing 0 of 12 cards                    ┃
┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
┃                                          ┃
┃              🎯                          ┃
┃                                          ┃
┃    No cards match your filters           ┃
┃                                          ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```

## Bottom Navigation (Updated)

```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃  📷       🗺️      🎴       📚           ┃
┃ Capture  Map    Codex   Journal         ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```

## Interaction Flows

### 1. Browse and Filter Flow
```
Codex Grid
   ↓
Tap Filter Chip
   ↓
Select Filter Value
   ↓
Grid Updates (filtered)
   ↓
Tap "Clear Filters"
   ↓
Grid Shows All Cards
```

### 2. Card Detail Flow
```
Codex Grid
   ↓
Tap Card
   ↓
Card Detail View Opens
   ↓
View Stats/Location/Traits
   ↓
Tap Back
   ↓
Return to Grid (filters preserved)
```

### 3. Capture New Card Flow
```
Camera Tab
   ↓
Capture Insect
   ↓
Save Capture
   ↓
Navigate to Codex
   ↓
New Card Appears in Grid
```

### 4. Search Flow
```
Codex Grid
   ↓
Type in Search Bar
   ↓
Grid Filters in Real-time
   ↓
Clear Search
   ↓
Grid Restores
```

## Responsive Design Notes

### Card Sizing
- Grid: 2 columns (fixed)
- Card aspect ratio: 0.75 (vertical cards)
- Spacing: 8px between cards
- Padding: 8px around grid

### Image Handling
- Photos displayed with `BoxFit.cover` in grid
- Photos displayed with `BoxFit.contain` in detail view
- Error handling: Shows bug icon placeholder if image fails to load

### Text Overflow
- Genus/species names: ellipsis after 1 line
- Group names: ellipsis after 1 line
- Detail view: Full text display (scrollable)

## Accessibility Considerations

- All interactive elements are Material widgets (accessible by default)
- Color is not the only indicator (icons + text labels)
- Touch targets meet minimum size requirements
- Semantic labels on icons
- High contrast between text and backgrounds

## Performance Optimizations

- AutomaticKeepAliveClientMixin: Preserves state and scroll position
- Efficient filtering: In-memory list filtering
- Image caching: Flutter's Image.file handles caching
- Lazy loading: GridView.builder only builds visible items
