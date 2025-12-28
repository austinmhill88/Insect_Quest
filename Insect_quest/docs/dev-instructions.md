# Build Plan: Android-only MVP (Flutter) – InsectQuest

## Overview
- Platform: Flutter (Android only for MVP).
- Features: Camera capture, on-device identification stub (genus-first, species suggestions), points with photo-quality multiplier, local coin minting, journal entries, private map with coarse location pins, Kids Mode toggle.
- Region: North Georgia, Georgia state species Legendary override (Honey Bee, Eastern Tiger Swallowtail).
- No server, trading, or IAP in MVP.

## Prerequisites
- Install Android Studio, Flutter SDK, and set PATH for `flutter`.
- Ensure a physical Android device or emulator is available.
- Obtain a Google Maps Android API key.

## Task 1: Scaffold Flutter App
1. Run: `flutter create insect_quest`
2. Open the project in Android Studio.
3. Replace `pubspec.yaml` with the file provided below.
4. Run `flutter pub get`.

Definition of Done:
- Flutter app builds and launches on Android (emulator or device).
- No runtime errors.

## Task 2: Configure Android Permissions and Maps Key
1. Insert camera and location permissions and Maps API key metadata in `AndroidManifest.xml` per the file below.
2. Create a string resource `google_maps_api_key` containing your key.

Definition of Done:
- App launches.
- Google Map renders on `MapPage` without API errors.

## Task 3: Implement Core Navigation and Pages
1. Create `lib/main.dart`, `lib/pages/camera_page.dart`, `lib/pages/map_page.dart`, `lib/pages/journal_page.dart` using provided files.
2. Verify bottom navigation switches correctly.

Definition of Done:
- Three tabs: Capture, Map, Journal.
- Camera preview works; can capture a photo.

## Task 4: Add Feature Flags, Scoring, and Catalog
1. Create `lib/config/feature_flags.dart` and `lib/config/scoring.dart`.
2. Add catalog asset `assets/catalogs/species_catalog_ga.json` and include in `pubspec.yaml` assets.
3. Create `lib/services/catalog_service.dart` to load catalog JSON (see stub).

Definition of Done:
- Catalog loads into memory at app start.
- Scoring function returns points given tier and quality.

## Task 5: Implement Quality Scoring (Local-only)
1. In `camera_page.dart`, after capture:
   - Compute sharpness using Laplacian variance (via `image` package).
   - Estimate exposure via histogram midtone ratio.
   - Estimate framing via ROI proportion (simple center crop heuristic).
2. Use `Scoring.qualityMultiplier()` to get quality multiplier.

Definition of Done:
- Quality multiplier computed between 0.85–1.15 (0.9 floor in Kids Mode).
- Values logged to console for debugging.

## Task 6: Identification Stub (Genus-first, Species Suggestions)
1. Implement `lib/services/ml_stub.dart`:
   - Return taxon path (order/family/genus) and 1–3 species candidates from catalog based on simple heuristics:
     - If photo taken in Georgia and catalog contains `state_species`, prefer those for suggestions.
     - If capture contains “butterfly” hints (e.g., wide wings in frame shape heuristic), suggest butterflies.
     - Fallback to genus-only.
2. Species confirmation:
   - Present a confirmation dialog with top suggestions; allow user to pick or keep genus-only.

Definition of Done:
- After capture, user sees genus or species suggestion dialog.
- Selecting species sets `speciesConfirmed = true`.

## Task 7: Data Model and Local Storage
1. Create `lib/models/capture.dart` for capture records (id, timestamp, coarse geocell, photo path, taxon, rarity tier, flags, points).
2. Store captures locally in `SharedPreferences` as a JSON list (MVP simplicity).
3. Journal lists captures with points, rarity, flags (state_species, invasive, venomous).

Definition of Done:
- Captures persist across app restarts.
- Journal shows saved entries.

## Task 8: Map with Coarse Location
1. Implement a `latLonToGeocell(lat, lon)` that rounds coordinates to a coarse grid (~1 km equivalent, e.g., 0.01° lat/lon).
2. Place markers at geocell centers for captures.
3. Kids Mode default: do not add captures to public map (MVP: treat all as private).

Definition of Done:
- Map shows coarse markers for captures.
- Tapping a marker shows summary (species/genus, points).

## Task 9: Rarity, Legendary Overrides, Kids Mode
1. Rarity tier derives from catalog entry. Apply Legendary overrides for Georgia `state_species`:
   - Honey Bee (Apis mellifera): Legendary.
   - Eastern Tiger Swallowtail (Papilio glaucus): Legendary.
2. Points: apply species confirmation bonus (+30%) only when species confirmed.
3. Kids Mode:
   - Toggle in app settings (simple switch in Journal or an app bar menu).
   - Kids Mode ON by default: quality floor 0.9; hide map markers; show safety tips banner on spiders.

Definition of Done:
- Honey Bee and Eastern Tiger Swallowtail award Legendary-tier points when species confirmed and quality ≥ 1.00; otherwise Epic-tier points but keep Legendary badge.
- Kids Mode toggling changes behavior accordingly.

## Task 10: Field Test Hooks
1. Add simple debug logging to console for: quality, tier, points.
2. Provide a “Retake” prompt if sharpness < 0.9 or framing < 0.9.

Definition of Done:
- Developer can assess capture quality via logs.
- Retake prompt appears for low-quality shots.

## Future (not in MVP)
- Server verification, trading, IAP, events, TestFlight/iOS.
