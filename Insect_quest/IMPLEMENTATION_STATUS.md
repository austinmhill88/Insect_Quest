# Implementation Checklist

This document tracks the completion status of all tasks from `docs/dev-instructions.md`.

## ✅ Task 1: Scaffold Flutter App
**Status:** COMPLETE

- ✅ Project structure created with proper directory layout
- ✅ `pubspec.yaml` configured with all required dependencies:
  - camera: ^0.11.0
  - google_maps_flutter: ^2.7.0
  - geolocator: ^12.0.0
  - tflite_flutter: ^0.11.0
  - image: ^4.1.3
  - http: ^1.2.0
  - shared_preferences: ^2.3.2
  - provider: ^6.1.2
  - uuid: ^4.5.0
- ✅ App builds and launches on Android

**Definition of Done:** ✅ Flutter app builds and launches on Android (emulator or device)

---

## ✅ Task 2: Configure Android Permissions and Maps Key
**Status:** COMPLETE

- ✅ Camera permission added to AndroidManifest.xml
- ✅ Location permissions (FINE and COARSE) added to AndroidManifest.xml
- ✅ Google Maps API key metadata configured in AndroidManifest.xml
- ✅ String resource `google_maps_api_key` created in `android/app/src/main/res/values/strings.xml`
- ✅ Placeholder provided for user's API key

**Files:**
- `android/app/src/main/AndroidManifest.xml` - Permissions and metadata
- `android/app/src/main/res/values/strings.xml` - API key resource

**Definition of Done:** ✅ App launches; Google Map renders on MapPage without API errors (once user adds their key)

---

## ✅ Task 3: Implement Core Navigation and Pages
**Status:** COMPLETE

- ✅ `lib/main.dart` - App entry point with bottom navigation
- ✅ `lib/pages/camera_page.dart` - Camera preview and capture functionality
- ✅ `lib/pages/map_page.dart` - Google Maps with markers
- ✅ `lib/pages/journal_page.dart` - Capture history list
- ✅ Bottom navigation switches correctly between tabs
- ✅ Camera preview works
- ✅ Photo capture functional

**Definition of Done:** ✅ Three tabs work: Capture, Map, Journal; Camera preview works; can capture a photo

---

## ✅ Task 4: Add Feature Flags, Scoring, and Catalog
**Status:** COMPLETE

- ✅ `lib/config/feature_flags.dart` - Feature toggles (Kids Mode default, etc.)
- ✅ `lib/config/scoring.dart` - Quality multiplier and points calculation
- ✅ `assets/catalogs/species_catalog_ga.json` - North Georgia species catalog
- ✅ Catalog included in `pubspec.yaml` assets
- ✅ `lib/services/catalog_service.dart` - Catalog loading and lookup

**Catalog includes:**
- Butterflies (4 species including Eastern Tiger Swallowtail)
- Bees/Wasps (3 entries including Honey Bee)
- Beetles (2 species)
- Arachnids – Spiders (3 species)
- Myriapods – Centipedes (1 species)
- Myriapods – Millipedes (2 entries)

**Definition of Done:** ✅ Catalog loads into memory at app start; Scoring function returns points given tier and quality

---

## ✅ Task 5: Implement Quality Scoring (Local-only)
**Status:** COMPLETE

Implemented in `lib/pages/camera_page.dart`:

- ✅ **Sharpness computation** using Laplacian variance
  - Samples pixels at 10-pixel intervals
  - Computes edge detection via Laplacian operator
  - Normalized to 0.85-1.10 range
  
- ✅ **Exposure estimation** via histogram midtone ratio
  - Samples pixels at 20-pixel intervals
  - Counts pixels in midtone range (60-190)
  - Returns ratio mapped to 0.90-1.05
  
- ✅ **Framing estimation** via ROI proportion
  - Compares center brightness vs edge brightness
  - Center defined as inner 25% radius
  - Returns 0.90-1.15 based on ratio

- ✅ `Scoring.qualityMultiplier()` used to combine metrics
  - Weights: 40% sharpness, 20% exposure, 40% framing
  - Clamped to 0.85-1.15 range
  - Kids Mode enforces 0.9 minimum

**Definition of Done:** ✅ Quality multiplier computed between 0.85–1.15 (0.9 floor in Kids Mode); Values logged to console for debugging

---

## ✅ Task 6: Identification Stub (Genus-first, Species Suggestions)
**Status:** COMPLETE

Implemented in `lib/services/ml_stub.dart`:

- ✅ Returns taxon path (order/family/genus)
- ✅ Returns 1-3 species candidates from catalog
- ✅ Prefers Georgia `state_species` when photo taken in Georgia
- ✅ Simple heuristics for butterfly vs bee identification
- ✅ Catalog service enhanced to support both species and genus lookups
- ✅ Genus extraction from species names (first word)

**Species confirmation dialog:**
- ✅ Presents top suggestions after capture
- ✅ Allows user to pick species or keep genus-only
- ✅ Sets `speciesConfirmed = true` when species selected
- ✅ Species confirmation bonus (+30%) applied to points

**Definition of Done:** ✅ After capture, user sees genus or species suggestion dialog; Selecting species sets speciesConfirmed = true

---

## ✅ Task 7: Data Model and Local Storage
**Status:** COMPLETE

- ✅ `lib/models/capture.dart` - Complete data model with:
  - ID, timestamp, coarse geocell
  - Photo path
  - Taxonomic info (group, genus, species)
  - Rarity tier
  - Flags (state_species, invasive, venomous)
  - Points and quality
  - JSON serialization (toJson/fromJson)

- ✅ Local storage via SharedPreferences
  - Saves captures as JSON list
  - Persists across app restarts
  - Load/save methods in `JournalPage`

- ✅ Journal displays:
  - Photo thumbnail
  - Species/genus name
  - Group, tier, points, geocell
  - Flag badges (state species, invasive, venomous)

**Definition of Done:** ✅ Captures persist across app restarts; Journal shows saved entries

---

## ✅ Task 8: Map with Coarse Location
**Status:** COMPLETE

Implemented in `lib/pages/map_page.dart`:

- ✅ **Coarse location function** `latLonToGeocell(lat, lon)`
  - Rounds coordinates to 0.01° (~1 km)
  - Implemented in `camera_page.dart` as `_geocell()`
  - Format: "34.00,-84.00"

- ✅ **Map markers** at geocell centers
  - Parses geocell string to get coarse lat/lon
  - Places markers at rounded coordinates
  - Info window shows species/genus and points

- ✅ **Kids Mode privacy**
  - Map markers hidden when Kids Mode is ON
  - Privacy banner displayed on map
  - Treats all captures as private in Kids Mode

**Definition of Done:** ✅ Map shows coarse markers for captures; Tapping marker shows summary; Kids Mode hides markers

---

## ✅ Task 9: Rarity, Legendary Overrides, Kids Mode
**Status:** COMPLETE

### Rarity and Legendary Overrides

- ✅ Rarity tier from catalog entry
- ✅ Georgia State Species Legendary overrides:
  - **Honey Bee** (Apis mellifera): Legendary tier in catalog
  - **Eastern Tiger Swallowtail** (Papilio glaucus): Legendary tier in catalog
  - Both have `state_species: true` flag

- ✅ **Legendary logic** (implemented in `camera_page.dart`):
  - If state species + Legendary tier + quality ≥ 1.00: Full Legendary points
  - If state species + Legendary tier + quality < 1.00: Epic points, Legendary badge
  - Uses separate `pointsTier` variable for calculation vs display

- ✅ **Species confirmation bonus**:
  - +30% points when `speciesConfirmed = true`
  - Applied in `Scoring.points()`

### Kids Mode Features

Implemented across multiple files:

- ✅ **Settings persistence** (`lib/services/settings_service.dart`)
  - Saves/loads Kids Mode state via SharedPreferences
  - Default: ON (per feature flags)

- ✅ **Toggle controls**:
  - Camera page: FilterChip at bottom-left
  - Journal page: FilterChip in app bar
  - Both sync via SettingsService

- ✅ **Quality floor enforcement**:
  - 0.9 minimum in Kids Mode (implemented in `Scoring.qualityMultiplier()`)
  - Normal mode: 0.85 minimum

- ✅ **Map markers hidden**:
  - Map page checks Kids Mode state
  - Empty marker set when Kids Mode ON
  - Privacy banner displayed

- ✅ **Safety tips for spiders**:
  - Dialog shown when group contains "Spider" and Kids Mode is ON
  - Safety message about observing from distance
  - No touching warning

**Definition of Done:** ✅ Honey Bee and Eastern Tiger Swallowtail award Legendary-tier points when species confirmed and quality ≥ 1.00; otherwise Epic-tier points but keep Legendary badge; Kids Mode toggling changes behavior accordingly

---

## ✅ Task 10: Field Test Hooks
**Status:** COMPLETE

- ✅ **Debug logging** (in `camera_page.dart`):
  ```dart
  debugPrint("Quality: s=$sharpness e=$exposure f=$framing qMult=$qMult");
  debugPrint("Taxon: group=$group genus=$genus species=$species tier=$tier flags=$flags");
  debugPrint("Points: $pts");
  ```

- ✅ **Retake prompt**:
  - Triggered when sharpness < 0.9 OR framing < 0.9
  - Dialog with "Keep anyway" or "Retake" options
  - Returns without saving if user chooses "Retake"

**Definition of Done:** ✅ Developer can assess capture quality via logs; Retake prompt appears for low-quality shots

---

## 📚 Additional Deliverables

Beyond the 10 tasks, the following were also created:

### Documentation

- ✅ **README.md** - Comprehensive user guide with:
  - Feature overview
  - Prerequisites and setup instructions
  - How to use the app
  - Technical details (quality scoring, point calculation)
  - Troubleshooting guide
  
- ✅ **SETUP.md** - Detailed developer setup guide with:
  - Step-by-step Flutter installation
  - Android Studio configuration
  - Google Maps API key setup
  - Build and run instructions
  - Troubleshooting for common issues
  - IDE configuration tips
  - Useful commands reference

- ✅ **.gitignore** - Flutter-specific ignores for:
  - Build artifacts
  - IDE configurations
  - Dependency caches
  - Generated files

### Code Quality

- ✅ All imports organized
- ✅ Consistent code style
- ✅ Proper error handling
- ✅ Type safety maintained
- ✅ Comments for complex logic

---

## ✅ Task 11: Kids Mode v2 - Parental Controls, Safe Quests, Enhanced Privacy
**Status:** COMPLETE

### Features Implemented

#### 1. Parental Control PIN System
- ✅ PIN setup dialog (`lib/widgets/pin_dialogs.dart`)
- ✅ PIN verification dialog
- ✅ PIN storage in SharedPreferences (`lib/services/settings_service.dart`)
- ✅ PIN protection on Kids Mode toggle (all pages)
- ✅ 4-8 digit PIN requirement
- ✅ PIN verification required to disable Kids Mode

#### 2. Safe Species Filtering
- ✅ Added `safe_for_kids` flag to all catalog entries
- ✅ Butterflies marked as safe (all 4 species)
- ✅ Bees marked as safe (Honey Bees, Bumblebees)
- ✅ Beetles marked as safe (all species)
- ✅ Millipedes marked as safe
- ✅ Spiders marked as unsafe (requires caution)
- ✅ Paper Wasps marked as unsafe (can sting)
- ✅ Centipedes marked as unsafe (can bite)
- ✅ ML stub filters species based on Kids Mode
- ✅ Only safe species suggested in Kids Mode

#### 3. Quest System
- ✅ Quest data model (`lib/models/quest.dart`)
- ✅ QuestProgress tracking model
- ✅ Quest service with safe quest filtering (`lib/services/quest_service.dart`)
- ✅ 6 safe quests for kids:
  - 🦋 Butterfly Beginner (3 butterflies, 100 pts)
  - 🐝 Bee Buddy (2 bees, 100 pts)
  - 🪲 Beetle Explorer (2 beetles, 100 pts)
  - ⭐ First Five Friends (5 insects, 150 pts)
  - 🌈 Diversity Explorer (3 groups, 200 pts)
  - 🌟 State Species Hunter (1 state species, 250 pts)
- ✅ 2 advanced quests filtered in Kids Mode
- ✅ Automatic quest progress tracking
- ✅ Quest completion notifications
- ✅ Quests tab in Journal with progress visualization

#### 4. Enhanced Privacy & Safety
- ✅ Coarse geocells maintained (~1km precision)
- ✅ Map markers hidden in Kids Mode (existing + PIN protected)
- ✅ Lower camera quality requirements (existing)
- ✅ Safety tips for spiders (existing)
- ✅ PIN protection prevents access to full map data

#### 5. Kid-Friendly UI
- ✅ Camera page enhancements:
  - Bright yellow framing guide (4px border)
  - Friendly emoji decorations (🦋🐝🪲🐞)
  - Encouraging banner: "Find a bug and take a photo!"
  - Larger, rounder UI elements
- ✅ Quest completion celebrations:
  - "🎉 Great job! You completed: [Quest Name]!"
  - Reward points displayed
- ✅ Color-coded UI elements:
  - Yellow for Kids Mode elements
  - Green for completed quests
  - Blue for active quests

#### 6. Quest Tab Integration
- ✅ Two-tab Journal interface (Captures | Quests)
- ✅ Visual progress bars for each quest
- ✅ Emoji icons for quest categories
- ✅ Completion status indicators
- ✅ Progress tracking (e.g., "3/5 • 150 pts")

### Files Created
- `lib/widgets/pin_dialogs.dart` - PIN UI components
- `lib/models/quest.dart` - Quest data models
- `lib/services/quest_service.dart` - Quest management
- `docs/KIDS_MODE_V2.md` - Comprehensive feature documentation

### Files Updated
- `lib/services/settings_service.dart` - Added PIN management
- `lib/services/ml_stub.dart` - Added safe species filtering
- `lib/pages/camera_page.dart` - PIN protection, kid UI, quest notifications
- `lib/pages/journal_page.dart` - PIN protection, Quests tab
- `lib/pages/map_page.dart` - PIN protection
- `assets/catalogs/species_catalog_ga.json` - Added safe_for_kids flags

**Definition of Done:** ✅ Kids Mode has PIN protection; All pages respect Kids Mode; Only safe species/quests shown; Kid-friendly UI with placeholder art (emojis)

---

## Summary

**All 10 MVP tasks + Kids Mode v2 are COMPLETE! ✅**

The app is ready for development with the following capabilities:

1. ✅ Camera capture with quality analysis
2. ✅ Species identification stub with state species preference
3. ✅ Points system with rarity tiers and quality multipliers
4. ✅ Legendary override logic for Georgia state species
5. ✅ Kids Mode v1 with safety features and privacy controls
6. ✅ Local storage with persistent journal
7. ✅ Map with coarse location markers
8. ✅ Debug logging for field testing
9. ✅ Retake prompt for quality control
10. ✅ Comprehensive documentation
11. ✅ **Kids Mode v2 with parental controls, safe quests, and enhanced UI**

### Kids Mode v2 Highlights

- 🔒 **Parental PIN Protection**: Secure 4-8 digit PIN prevents unauthorized setting changes
- 🦋 **Safe Species Only**: Filtered catalog with kid-friendly insects only
- 🎯 **Learning Quests**: 6 educational quests with progress tracking
- 🌈 **Friendly UI**: Colorful overlays, emojis, and encouraging messages
- 🗺️ **Enhanced Privacy**: PIN-protected map controls, coarse locations
- 📊 **Progress Tracking**: New Quests tab shows achievements and progress

### Next Steps for Users

1. Install Flutter and Android Studio (see SETUP.md)
2. Clone the repository
3. Add Google Maps API key to `android/app/src/main/res/values/strings.xml`
4. Run `flutter pub get`
5. Run `flutter run`
6. Enable Kids Mode and set up a PIN
7. Start capturing insects and completing quests! 🐛🦋🐝

### Future Enhancements (Post-MVP)

The following are noted in the docs but NOT implemented (as intended):
- ❌ Server verification
- ❌ Trading system
- ❌ In-app purchases
- ❌ Events
- ❌ iOS support
- ❌ TestFlight
- 💡 Multiple child profiles
- 💡 Customizable difficulty levels
- 💡 Parental dashboard
- 💡 Audio guidance

These will be addressed in future iterations.
