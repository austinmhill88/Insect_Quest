# Kids Mode v2 Migration Guide

## Overview

This guide helps users understand the changes between Kids Mode v1 and Kids Mode v2, and what to expect when upgrading.

## What's New in Kids Mode v2?

### Major New Features

1. **Parental PIN Protection** 🔒
   - NEW: 4-8 digit PIN required to disable Kids Mode
   - Prevents children from turning off safety features
   - One-time setup on first disable attempt
   
2. **Safe Species Filtering** 🦋
   - NEW: Only kid-friendly species suggested in Kids Mode
   - Safe: Butterflies, bees, beetles, millipedes
   - Filtered: Spiders, wasps, centipedes
   
3. **Quest System** 🎯
   - NEW: 6 learning-focused quests for kids
   - Automatic progress tracking
   - Celebration notifications
   - New Quests tab in Journal
   
4. **Enhanced UI** 🌈
   - NEW: Colorful camera overlay with emojis
   - NEW: Encouraging messages and banners
   - NEW: Larger, friendlier buttons and frames

## What's Staying the Same?

Features from Kids Mode v1 that are preserved:

✅ Coarse location (geocells) - privacy maintained
✅ Hidden map markers in Kids Mode
✅ Lower camera quality requirements
✅ Safety tips for risky species
✅ Kids Mode toggle available on Camera and Journal pages

## Breaking Changes

### For Parents

**IMPORTANT:** After upgrading, the first time you try to disable Kids Mode, you'll be prompted to create a PIN.

**Action Required:**
1. Choose a memorable 4-8 digit PIN
2. Write it down in a safe place
3. Do NOT share it with your child

**If you forget your PIN:**
Currently, you'll need to:
1. Uninstall and reinstall the app (this will reset all data), OR
2. Clear app data in Android Settings → Apps → InsectQuest → Storage → Clear Data

⚠️ **Warning:** Clearing app data will delete all captures and quest progress.

### For Developers

**Data Migration:**
- No automatic data migration required
- Quest progress starts fresh for all users
- PIN storage uses new SharedPreferences keys
- Existing captures are compatible

**API Changes:**
```dart
// OLD - Kids Mode v1
final analysis = await ml.analyze(imagePath: file.path, lat: lat, lon: lon);

// NEW - Kids Mode v2
final analysis = await ml.analyze(
  imagePath: file.path, 
  lat: lat, 
  lon: lon, 
  kidsMode: kidsMode,  // NEW parameter
);
```

## Upgrade Checklist

### For Parents

- [ ] Update to latest version from app store
- [ ] Launch the app - Kids Mode setting is preserved
- [ ] Try to disable Kids Mode to set up your PIN
- [ ] Write down your PIN in a secure location
- [ ] Review new Quests tab with your child
- [ ] Explain safe species guidelines to your child
- [ ] Test PIN protection works as expected

### For Developers

- [ ] Update Flutter dependencies if needed
- [ ] Pull latest code from repository
- [ ] Review `KIDS_MODE_V2.md` documentation
- [ ] Update any custom species catalogs with `safe_for_kids` flags
- [ ] Test PIN flow on all pages
- [ ] Test quest tracking with real captures
- [ ] Verify species filtering works correctly
- [ ] Update any custom themes to support Kids Mode colors

## Backward Compatibility

### Existing Data

✅ **Captures:** All existing captures are preserved and compatible
✅ **Kids Mode Setting:** Your Kids Mode preference is maintained
✅ **Species Catalog:** Extended with new flags, existing entries intact
✅ **Photos:** All captured photos remain accessible

❌ **Quest Progress:** No historical quest progress (quests are new)
❌ **PIN:** No existing PIN (must be set up on first disable attempt)

## Feature Comparison

| Feature                    | v1   | v2   | Notes                          |
|----------------------------|------|------|--------------------------------|
| Kids Mode Toggle           | ✅   | ✅   | Now PIN protected              |
| Coarse Location            | ✅   | ✅   | Unchanged                      |
| Hidden Map Markers         | ✅   | ✅   | Now PIN protected              |
| Safety Tips                | ✅   | ✅   | Unchanged                      |
| Lower Quality Requirements | ✅   | ✅   | Unchanged                      |
| **PIN Protection**         | ❌   | ✅   | **NEW**                        |
| **Safe Species Filter**    | ❌   | ✅   | **NEW**                        |
| **Quest System**           | ❌   | ✅   | **NEW**                        |
| **Kid-Friendly UI**        | ❌   | ✅   | **NEW**                        |
| **Quests Tab**             | ❌   | ✅   | **NEW**                        |

## Common Questions

### Q: Will my child's existing captures be deleted?
**A:** No, all captures are preserved during the upgrade.

### Q: Can my child turn off Kids Mode?
**A:** No, after you set up a PIN, only someone with the PIN can disable Kids Mode.

### Q: What if I forget my PIN?
**A:** Currently, you'll need to clear app data or reinstall. Future versions may include a recovery mechanism.

### Q: Can I change my PIN after setting it?
**A:** Not in the current UI. You can call `SettingsService.clearPin()` and set a new one, but this requires code access.

### Q: Will spiders still show safety warnings?
**A:** Yes, but in Kids Mode v2, spiders are filtered out of suggestions. The safety warning only appears if a spider is somehow identified.

### Q: Are the quests mandatory?
**A:** No, quests are optional. They provide learning goals but don't restrict app usage.

### Q: Can I add custom quests?
**A:** Yes! Edit `lib/services/quest_service.dart` and add new `Quest` objects to the `allQuests` list.

### Q: What about iOS?
**A:** Kids Mode v2 is Android-only (like the rest of the app). iOS support is planned for future releases.

## Troubleshooting

### Issue: PIN dialog doesn't appear
**Solution:** 
1. Check Kids Mode is enabled
2. Try toggling Kids Mode off
3. Ensure app has latest code

### Issue: Quest progress not tracking
**Solution:**
1. Verify captures are being saved
2. Check quest requirements match capture type
3. Review `quest_service.dart` logic

### Issue: Safe species filter not working
**Solution:**
1. Verify catalog has `safe_for_kids` flags
2. Check `ml_stub.dart` receives `kidsMode` parameter
3. Test with known safe species (butterflies)

### Issue: Emoji not displaying correctly
**Solution:**
1. Update device system to support latest Unicode
2. Use device with good emoji support
3. Consider replacing emojis with image assets

### Issue: PIN forgotten
**Solution:**
1. Go to Android Settings → Apps → InsectQuest
2. Select Storage → Clear Data
3. ⚠️ Warning: This deletes all captures and progress
4. Alternative: Reinstall the app

## Rolling Back (Not Recommended)

If you need to revert to Kids Mode v1:

1. Checkout previous git commit (before Kids Mode v2)
2. Remove new files:
   - `lib/widgets/pin_dialogs.dart`
   - `lib/models/quest.dart`
   - `lib/services/quest_service.dart`
3. Revert catalog changes in `species_catalog_ga.json`
4. Remove quest-related imports and code
5. Rebuild and deploy

⚠️ **Warning:** Rolling back will lose quest progress and PIN protection.

## Future Improvements

Planned for future Kids Mode versions:

- 🔄 PIN recovery via email/security questions
- 👥 Multiple child profiles
- 📊 Parental dashboard
- 🎨 Custom theme creator
- 🔊 Audio guidance for young readers
- ⏰ Time limits and screen time controls
- 🏅 More quest types and difficulty levels
- 🌍 Region-specific quest sets

## Getting Help

- 📖 Read `docs/KIDS_MODE_V2.md` for detailed features
- 🎨 Check `docs/KIDS_MODE_V2_UI_GUIDE.md` for UI examples
- 🐛 Report bugs via GitHub Issues
- 💬 Ask questions in Discussions

## Feedback Welcome!

Kids Mode v2 is designed based on best practices for child safety and learning. We welcome feedback from:

- Parents using the app with children
- Educators incorporating the app in lessons
- Child development specialists
- Security researchers

Please share your experience and suggestions!

---

**Thank you for keeping kids safe while learning about nature! 🦋🐝🌈**
