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
- 👶 Kids Mode with enhanced safety features
- 💰 **Coin Economy**: Earn coins by minting cards (capturing insects)
- 🔄 **Trading System**: List cards, propose swaps (1:1 or with coins), escrow support

🎯 **Kids Mode Benefits:**
- Quality floor locked at 0.9 minimum
- Map markers hidden for privacy
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

💸 **Economy System:**
- Coins awarded when capturing insects (minting cards)
- Base coin amounts by rarity (50-1500 base coins)
- Quality multiplier affects coin rewards
- User profile with coin balance synced to Firestore
- Trading marketplace with escrow system
- List cards for trade with coin offers
- Accept/cancel trades with automatic coin transfers

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

4. **Firebase Project** (Optional for Economy/Trading)
   - Required for cloud sync of coins and trades
   - See `docs/firebase_setup.md` for detailed setup
   - App works in offline mode without Firebase

5. **Physical Android Device or Emulator**
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

### 3. (Optional) Configure Firebase

For economy and trading features with cloud sync:

1. Follow the detailed setup in `docs/firebase_setup.md`
2. Download `google-services.json` from Firebase Console
3. Place in `android/app/google-services.json`

**Note:** App works without Firebase, but Economy/Trading features will show errors.

### 4. Install Dependencies

```bash
flutter pub get
```

### 5. Connect Device or Start Emulator

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

### 6. Build and Run

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
│   │   ├── map_page.dart         # Google Maps with coarse location markers
│   │   ├── journal_page.dart     # List of captures with stats and flags
│   │   ├── economy_page.dart     # Coin balance and economy overview
│   │   └── trading_page.dart     # Trading marketplace for card swaps
│   ├── services/
│   │   ├── catalog_service.dart  # Species catalog loader and lookup
│   │   ├── ml_stub.dart          # Identification stub (heuristic-based)
│   │   ├── settings_service.dart # Persistent settings (Kids Mode)
│   │   ├── firestore_service.dart # Firebase cloud storage for coins/trades
│   │   └── user_service.dart     # User ID management
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
    ├── dev-instructions.md       # Detailed development instructions
    ├── firebase_setup.md         # Firebase/Firestore configuration guide
    └── theming.md                # UI customization for economy features
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
8. **Capture Saved**: Points and coins awarded and added to your journal!

### Viewing the Map

1. **Navigate to the Map Tab** (map icon)
2. **View markers** at coarse locations (~1km accuracy)
3. **Tap markers** to see species/genus and points
4. **Kids Mode**: Map markers are hidden for privacy

### Reviewing Your Journal

1. **Navigate to the Journal Tab** (book icon)
2. **Toggle Kids Mode** from the app bar if desired
3. **Scroll through captures** with photos, stats, and badges (including coins earned)
4. **Pull down** to refresh the list

### Managing Your Economy

1. **Navigate to the Economy Tab** (wallet icon)
2. **View your coin balance** synced to Firestore
3. **Learn about earning coins** from the info card
4. **Access trading** via the Trading button

### Trading Cards

1. **From Economy page**, tap "Trading" or navigate to Trading page
2. **View Available Trades** tab to see other players' listings
3. **Create a trade**: Tap FAB (+), select card, set coin amounts
4. **Accept a trade**: Tap "Accept" on any listing, coins locked in escrow
5. **Manage your trades**: View "My Trades" tab, cancel if needed
6. **Complete trades**: Cards and coins transfer automatically

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

**Economy/Trading not working:**
- Check Firebase setup in `docs/firebase_setup.md`
- Verify `google-services.json` is in `android/app/`
- Check Firestore security rules
- App works offline but Economy features require Firebase

**"Insufficient coins" error:**
- Check your coin balance in Economy tab
- Capture more insects to earn coins
- Verify Firestore sync is working

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

### Coin Calculation

```
Base Coins × Rarity Multiplier × Quality Multiplier
```

**Base Coin Rewards:**
- Common: 50 coins (50-57 after quality)
- Uncommon: 112 coins (95-129 after quality)
- Rare: 300 coins (255-345 after quality)
- Epic: 720 coins (612-828 after quality)
- Legendary: 1500 coins (1275-1725 after quality)

### Trading System

- **Listing**: Players list cards with optional coin offers/requests
- **Escrow**: When trade accepted, requested coins locked
- **Completion**: Cards swap, coins transfer atomically
- **Cancellation**: Escrowed coins refunded to buyer

### Coarse Location

Coordinates are rounded to 0.01° (~1km) for privacy:
```dart
latRounded = (lat * 100).round() / 100.0
lonRounded = (lon * 100).round() / 100.0
```

## Future Enhancements (Post-MVP)

- [ ] Server-side verification of photos
- [x] Trading system for duplicate captures (MVP implemented!)
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
