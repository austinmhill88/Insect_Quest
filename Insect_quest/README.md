# InsectQuest - Real-world Arthropod Collecting Game

An Android-only MVP Flutter application for discovering and cataloging insects and arthropods in the wild.

## Features

✨ **Core Features:**
- 📸 Camera capture with quality analysis (sharpness, exposure, framing)
- 🔍 On-device identification stub (genus-first approach with species suggestions)
- ⭐ Rarity-based point system (Common to Legendary tiers)
- 📊 Photo quality multiplier (0.85-1.15x)
- 📝 Journal with persistent capture history
- 🗺️ Map with coarse location markers (~1km geocells)
- 🏆 Regional leaderboards by card count and points
- 👶 Kids Mode with enhanced safety features
- 🎯 Daily and Weekly Quests for ongoing engagement
- 🔥 Streak tracking system
- 🏆 Achievement system with set/milestone completions
- 💰 Coin economy for quest rewards

🎯 **Quest System:**
- Daily quests refresh every day at midnight
- Weekly quests refresh every Monday
- Quest types:
  - Capture any insect
  - Capture specific groups (pollinators, urban species, etc.)
  - Capture with quality thresholds
  - Diversity challenges (unique groups)
- Rewards: Coins and foil card chances
- Real-time progress tracking
- Claim rewards when quests are completed

🔥 **Streak & Achievements:**
- Track consecutive days of exploration
- View current and longest streak
- 10+ achievements to unlock
- Set completion achievements (Butterflies, Bees, Spiders)
- Milestone achievements (10, 50, 100 captures)
- Streak achievements (7-day, 30-day)
- Achievement rewards contribute to coin balance

👶 **Kids Mode Benefits:**
- 🛡️ Anti-cheat system with EXIF, duplicate detection, and optional liveness checks

🎯 **Kids Mode Benefits:**
- Quality floor locked at 0.9 minimum
- Map markers hidden for privacy
- Leaderboards hidden for privacy
- Safety tips banner when encountering spiders
- Toggle available on Camera and Journal pages

🏆 **Special Features:**
- Georgia State Species (Legendary tier):
  - Eastern Tiger Swallowtail (*Papilio glaucus*)
  - Honey Bee (*Apis mellifera*)
  - Legendary points awarded with quality ≥ 1.00
  - Epic points awarded otherwise, but Legendary badge retained
- Species confirmation bonus: +30% points
- Retake prompt for low-quality photos (sharpness < 0.9 or framing < 0.9)

🛡️ **Anti-Cheat & Validation:**
- **EXIF Validation**: Detects and blocks screenshots, scans, or edited photos
- **Duplicate Detection**: Prevents multiple mints from the same photo using perceptual hashing
- **Liveness Check**: Optional camera movement verification for rare/legendary captures
- **Admin Panel**: Review flagged/rejected captures with detailed logs
- All validation checks can be toggled via feature flags

## Prerequisites

Before you begin, ensure you have:

1. **Flutter SDK** (>= 3.3.0)
   - Install from: https://flutter.dev/docs/get-started/install
   - Add Flutter to your PATH

2. **Android Studio**
   - Install from: https://developer.android.com/studio
   - Install Android SDK and emulator

3. **Google Maps API Key**
   - Create a project in [Google Cloud Console](https://console.cloud.google.com)
   - Enable "Maps SDK for Android"
   - Create credentials → API Key
   - Restrict the key to Android apps (optional but recommended)

4. **Physical Android Device or Emulator**
   - Camera and location permissions required
   - Physical device recommended for best camera experience

## Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/austinmhill88/Insect_Quest.git
cd Insect_Quest/Insect_quest
```

### 2. Configure Google Maps API Key

Edit `android/app/src/main/res/values/strings.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="google_maps_api_key">YOUR_ACTUAL_API_KEY_HERE</string>
</resources>
```

Replace `YOUR_ACTUAL_API_KEY_HERE` with your Google Maps API key.

### 3. Install Dependencies

```bash
flutter pub get
```

### 4. Connect Device or Start Emulator

**For Physical Device:**
```bash
# Enable USB debugging on your Android device
# Connect via USB
flutter devices  # Verify device is detected
```

**For Emulator:**
```bash
# Open Android Studio
# Tools → AVD Manager → Create/Start virtual device
flutter devices  # Verify emulator is detected
```

### 5. Build and Run

```bash
flutter run
```

Or in Android Studio:
- Open the project
- Select your device/emulator
- Click the Run button (green triangle)

## Project Structure

```
Insect_quest/
├── lib/
│   ├── main.dart                 # App entry point with bottom navigation
│   ├── config/
│   │   ├── feature_flags.dart    # Feature toggles (Kids Mode default, etc.)
│   │   └── scoring.dart          # Point calculation and quality multipliers
│   ├── models/
│   │   └── capture.dart          # Capture data model with JSON serialization
│   ├── pages/
│   │   ├── camera_page.dart      # Camera preview, capture, and quality analysis
│   │   ├── map_page.dart         # Google Maps with aggregate geocell markers
│   │   ├── journal_page.dart     # List of captures with stats and flags
│   │   └── leaderboard_page.dart # Regional leaderboard by card count and points
│   ├── services/
│   │   ├── catalog_service.dart  # Species catalog loader and lookup
│   │   ├── ml_stub.dart          # Identification stub (heuristic-based)
│   │   ├── settings_service.dart # Persistent settings (Kids Mode)
│   │   └── leaderboard_service.dart # Geocell aggregation and statistics
│   └── assets/
│       └── catalogs/
│           └── species_catalog_ga.json  # North Georgia species catalog
├── android/
│   └── app/
│       └── src/
│           └── main/
│               ├── AndroidManifest.xml   # Permissions and Maps API key
│               └── res/
│                   └── values/
│                       └── strings.xml   # Google Maps API key resource
└── docs/
    └── dev-instructions.md       # Detailed development instructions
```

## How to Use

### Capturing an Insect

1. **Navigate to the Capture Tab** (camera icon)
2. **Toggle Kids Mode** if desired (bottom-left chip)
3. **Frame the insect** within the overlay guide
4. **Tap the Capture button**
5. **Quality Check**: If quality is low, you'll be prompted to retake
6. **Species Suggestion**: Review and select from suggested species or keep genus-only
7. **Safety Tips**: If it's a spider and Kids Mode is on, you'll see a safety banner
8. **Capture Saved**: Points awarded and added to your journal!

### Viewing the Map

1. **Navigate to the Map Tab** (map icon)
2. **View aggregate markers** at coarse locations (~1km geocells)
3. **Each marker shows** total card count for that region
4. **Tap markers** to see the leader list for that geocell
5. **Bottom sheet displays** all captures in that region, sorted by points
6. **Kids Mode**: Map markers are hidden for privacy

### Checking Regional Leaderboards

1. **Navigate to the Leaders Tab** (trophy icon)
2. **View regions ranked** by total points earned
3. **Top 3 regions** get medal badges (gold, silver, bronze)
4. **Each entry shows** card count, unique species, and total points
5. **Tap any region** to see detailed capture list
6. **Kids Mode**: Leaderboards are hidden for privacy

### Reviewing Your Journal

1. **Navigate to the Journal Tab** (book icon)
2. **Toggle Kids Mode** from the app bar if desired
3. **Scroll through captures** with photos, stats, and badges
4. **Pull down** to refresh the list

## Troubleshooting

### Common Issues

**App won't build:**
- Run `flutter clean && flutter pub get`
- Check Flutter version: `flutter --version`
- Ensure Android SDK is installed

**Camera not working:**
- Check AndroidManifest.xml has camera permission
- Grant camera permission in device settings
- Try on a physical device instead of emulator

**Map shows blank:**
- Verify Google Maps API key is correct in strings.xml
- Enable "Maps SDK for Android" in Google Cloud Console
- Check API key restrictions aren't blocking the app

**Location not available:**
- Check AndroidManifest.xml has location permissions
- Grant location permission in device settings
- Enable location services on device

**Captures not persisting:**
- SharedPreferences is used for storage
- Clear app data: Settings → Apps → InsectQuest → Clear Data
- Check for storage permission issues

## Development

### Running Tests

```bash
flutter test
```

### Linting

```bash
flutter analyze
```

### Building APK

```bash
flutter build apk --release
```

The APK will be at: `build/app/outputs/flutter-apk/app-release.apk`

## Technical Details

### Quality Scoring

Photos are analyzed for three factors:

1. **Sharpness** (40% weight): Laplacian variance for focus detection
2. **Exposure** (20% weight): Histogram midtone ratio
3. **Framing** (40% weight): Center vs edge brightness ratio

Final multiplier: `0.85 - 1.15x` (or `0.9 - 1.15x` in Kids Mode)

### Point Calculation

```
Base Points × Rarity Multiplier × Quality Multiplier [× 1.30 if species confirmed] [× 1.15 if first genus]
```

**Rarity Tiers:**
- Common: 50 base, 1.0x multiplier
- Uncommon: 75 base, 1.5x multiplier
- Rare: 120 base, 2.5x multiplier
- Epic: 180 base, 4.0x multiplier
- Legendary: 250 base, 6.0x multiplier

### Coarse Location & Geocells

**Privacy-First Design:** No precise locations are stored or displayed. All location data uses coarse geocells.

Coordinates are rounded to 0.01° (~1km) for privacy:
```dart
latRounded = (lat * 100).round() / 100.0
lonRounded = (lon * 100).round() / 100.0
geocell = "34.00,-84.00" // String key format
```

copilot/add-geocell-map-and-leaderboards
**Geocell Features:**
- Each geocell represents approximately 1 km² area
- Map markers aggregate all captures within the same geocell
- Leaderboards rank regions by geocell performance
- Kids Mode further restricts visibility of all geocell data

**Database Storage:**
- Only geocell string keys are stored (e.g., "34.00,-84.00")
- Original precise lat/lon coordinates are NOT persisted
- All map and leaderboard logic uses geocell aggregation

### Anti-Cheat System

The app includes a multi-layered anti-cheat system to ensure fair play:

**EXIF Validation**:
- Checks for camera metadata (Make, Model, DateTime)
- Blocks screenshots and edited photos
- Configurable via `Flags.exifValidationEnabled`

**Duplicate Detection**:
- Uses perceptual hashing (dHash algorithm)
- Detects identical and near-identical photos
- Prevents multiple mints from same capture
- Configurable via `Flags.duplicateDetectionEnabled`

**Liveness Check** (Optional):
- Requires camera movement for rare/legendary captures
- Prevents photo-of-photo fraud
- Disabled by default
- Enable via `Flags.livenessCheckEnabled`

**Admin Panel**:
- Access from Journal page (admin icon)
- View all flagged/rejected captures
- Review validation reasons and timestamps
- Clear logs functionality

For detailed documentation, see [`docs/anti_cheat_system.md`](docs/anti_cheat_system.md)
main

## Future Enhancements (Post-MVP)

- [ ] Server-side verification of photos
- [ ] Trading system for duplicate captures
- [ ] In-app purchases for premium features
- [ ] Events and challenges
- [ ] iOS support (TestFlight)
- [ ] Machine learning model integration
- [ ] Social features and leaderboards

## License

This project is for educational and personal use.

## Credits

Developed as an MVP Android application for arthropod enthusiasts in North Georgia.

---

**Happy Bug Hunting!** 🐛🦋🐝
