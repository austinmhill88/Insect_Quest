# Kids Mode v2 - Features Documentation

## Overview

Kids Mode v2 introduces comprehensive parental controls, safe species filtering, a quest system, and enhanced kid-friendly UI to make InsectQuest safe and fun for children.

## Features

### 1. Parental Control PIN System

**Purpose:** Prevent children from disabling Kids Mode without adult supervision.

**How it works:**
- When a parent tries to disable Kids Mode for the first time, they're prompted to create a 4-8 digit PIN
- The PIN is securely stored using SharedPreferences
- Subsequent attempts to disable Kids Mode require PIN verification
- PIN verification is required on all pages: Camera, Journal, and Map

**Usage:**
1. Enable Kids Mode by tapping the "Kids Mode" chip
2. Try to disable Kids Mode - you'll be prompted to set up a PIN
3. Enter and confirm your PIN
4. Future disable attempts will require entering this PIN

### 2. Safe Species Filtering

**Purpose:** Ensure children only encounter age-appropriate insects in the app.

**Safe Species Categories:**
- ✅ **Safe for Kids:**
  - All Butterflies (Papilio glaucus, Papilio troilus, Danaus plexippus, Pieris rapae)
  - Honey Bees (Apis mellifera)
  - Bumblebees (Bombus spp.)
  - Beetles (Dynastes tityus, Harmonia axyridis)
  - Millipedes (Apheloria tigana, Narceus spp.)

- ❌ **Not Safe for Kids (filtered out):**
  - Spiders (all species) - require caution and distance
  - Paper Wasps (Polistes) - can sting
  - Centipedes - can bite

**How it works:**
- Species catalog entries now have a `safe_for_kids` flag
- ML identification service filters suggestions based on Kids Mode
- Only safe species appear in identification results when Kids Mode is enabled
- Safety tips are shown for borderline species (like spiders) if accidentally captured

### 3. Quest System

**Purpose:** Provide learning-focused goals that encourage safe exploration.

**Safe Quests for Kids:**
- 🦋 **Butterfly Beginner**: Photograph 3 butterflies and learn about their wings! (100 pts)
- 🐝 **Bee Buddy**: Find and photograph 2 bees. They help plants grow! (100 pts)
- 🪲 **Beetle Explorer**: Discover 2 different beetles in your area (100 pts)
- ⭐ **First Five Friends**: Capture your first 5 insects! Great start! (150 pts)
- 🌈 **Diversity Explorer**: Find insects from 3 different groups (200 pts)
- 🌟 **State Species Hunter**: Find a Georgia state species! (250 pts)

**Advanced Quests (filtered in Kids Mode):**
- 🕷️ Spider Watcher (requires extra caution)
- 🏆 Collector Pro (advanced goal)

**How it works:**
- Quest progress is automatically tracked with each capture
- Completed quests show a celebration message
- Kids Mode filters quests to only show safe, age-appropriate challenges
- Progress is displayed on the "Quests" tab in the Journal

**Using the Quest System:**
1. Navigate to Journal → Quests tab
2. View available quests and your progress
3. Capture insects that match quest requirements
4. Get automatic notifications when quests are completed
5. Earn bonus points for completing quests

### 4. Enhanced Privacy & Safety

**Existing Features Enhanced:**
- ✅ Coarse geocells (~1km precision) - prevents exact location disclosure
- ✅ Map markers hidden in Kids Mode - no location data visible
- ✅ Lower camera quality requirements - easier for kids to take acceptable photos
- ✅ Safety tips for spiders and other potentially risky species

**New Privacy Features:**
- PIN protection prevents children from accessing full map data
- All Kids Mode settings are persistent and secure

### 5. Kid-Friendly UI

**Camera Page Enhancements:**
- 🌟 Bright yellow framing guide (larger, more visible than normal mode)
- 🦋🐝🪲🐞 Friendly emoji decorations in corners of camera frame
- Encouraging banner: "Find a bug and take a photo!"
- Larger, rounder UI elements
- Celebration messages for completed quests

**Color Scheme:**
- Bright yellow accents for Kids Mode elements
- Green success indicators for completed quests
- Friendly emoji icons throughout

**Encouraging Messages:**
- "🎉 Great job! You completed: [Quest Name]!"
- "🛡️ Kids Mode enabled - Safe and fun!"
- Progress feedback with every capture

### 6. Quest Tab in Journal

**New Journal Features:**
- Two-tab interface: Captures and Quests
- Visual progress bars for each quest
- Emoji icons for quest categories
- Color-coded completion status (green for completed)
- Clear progress indicators (e.g., "3/5 • 150 pts")

## Technical Implementation

### New Files Created

1. **`lib/widgets/pin_dialogs.dart`**
   - `PinSetupDialog`: First-time PIN creation
   - `PinVerifyDialog`: PIN verification for disabling Kids Mode

2. **`lib/models/quest.dart`**
   - `Quest`: Quest data model
   - `QuestProgress`: Progress tracking model

3. **`lib/services/quest_service.dart`**
   - Quest management and filtering
   - Automatic progress tracking
   - Safe quest filtering based on Kids Mode

### Updated Files

1. **`lib/services/settings_service.dart`**
   - Added PIN storage and verification methods
   - `isPinSetup()`, `setPin()`, `verifyPin()`, `clearPin()`

2. **`lib/services/ml_stub.dart`**
   - Added `kidsMode` parameter to `analyze()` method
   - Filters species suggestions to safe species only in Kids Mode

3. **`lib/pages/camera_page.dart`**
   - PIN-protected Kids Mode toggle
   - Kid-friendly camera overlay with emojis
   - Encouraging banner for kids
   - Quest completion notifications
   - Integrated quest progress tracking

4. **`lib/pages/journal_page.dart`**
   - PIN-protected Kids Mode toggle
   - New Quests tab with progress visualization
   - Tab controller for switching between Captures and Quests

5. **`lib/pages/map_page.dart`**
   - PIN-protected Kids Mode toggle (no toggle displayed, but respects setting)
   - Enhanced privacy message

6. **`assets/catalogs/species_catalog_ga.json`**
   - Added `safe_for_kids` flag to all species entries
   - Safe: Butterflies, Honey Bees, Bumblebees, Beetles, Millipedes
   - Unsafe: Spiders, Paper Wasps, Centipedes

## Usage Guide for Parents

### Setting Up Kids Mode

1. Launch the app and navigate to the Camera page
2. Tap the "Kids Mode" chip to enable it
3. The app is now in Kids Mode - your child will see:
   - Friendly, colorful camera interface
   - Safe insect suggestions only
   - Learning-focused quests
   - Hidden map markers for privacy

### Disabling Kids Mode

1. Tap the "Kids Mode" chip to disable it
2. On first disable, you'll be prompted to create a PIN
3. Enter and confirm a 4-8 digit PIN
4. Future disable attempts will require this PIN
5. Enter your PIN to disable Kids Mode

### Monitoring Progress

- Check the Quests tab to see what your child has accomplished
- Review captured insects in the Captures tab
- All captures are safe and age-appropriate when Kids Mode is enabled

### Security Notes

- PIN is stored securely using SharedPreferences
- Kids Mode state persists across app restarts
- All three pages (Camera, Journal, Map) respect Kids Mode settings
- PIN is required to change settings, not to use the app

## Benefits for Children

- ✅ **Safe Species**: Only encounter friendly, safe insects
- ✅ **Learning Goals**: Educational quests teach about nature
- ✅ **Privacy**: Location data is protected and coarse
- ✅ **Encouragement**: Positive feedback and celebration messages
- ✅ **Fun UI**: Colorful, friendly interface with emojis
- ✅ **Lower Barriers**: Easier photo quality requirements
- ✅ **Achievement System**: Quests provide clear goals and rewards

## Benefits for Parents

- ✅ **Control**: PIN protection prevents unauthorized setting changes
- ✅ **Safety**: Filtered species list excludes potentially risky insects
- ✅ **Privacy**: Map markers hidden, coarse location only
- ✅ **Education**: Quests encourage learning about insects and nature
- ✅ **Peace of Mind**: Comprehensive safety features built-in
- ✅ **Monitoring**: Easy to see child's progress and achievements

## Future Enhancements

Potential improvements for future versions:

- Multiple child profiles with separate progress
- Customizable quest difficulty levels
- Parental dashboard with detailed progress reports
- Time limits and daily goals
- Additional kid-friendly themes
- Audio guidance for young readers
- More granular safety controls
- Integration with educational content

## Support

For questions or issues with Kids Mode:
1. Check that all pages have Kids Mode enabled consistently
2. Verify PIN is working correctly
3. Review quest progress in the Journal
4. Ensure species catalog has safe_for_kids flags

## Code Architecture

### PIN Flow
```
User toggles Kids Mode OFF
  → Check if PIN is setup (isPinSetup())
  → If not, show PinSetupDialog
  → Store PIN (setPin())
  → Show PinVerifyDialog
  → Verify entered PIN (verifyPin())
  → If valid, disable Kids Mode
  → If invalid, show error and keep Kids Mode enabled
```

### Species Filtering Flow
```
Capture photo
  → Call ML analyze with kidsMode flag
  → ML service filters catalog to safe species
  → Return only safe suggestions
  → Present filtered list to user
```

### Quest Progress Flow
```
Save capture
  → Call QuestService.updateProgressForCapture()
  → Check all active quests
  → Increment progress for matching quests
  → Mark quests as completed if target reached
  → Return list of newly completed quests
  → Show celebration notification
```

## Testing Checklist

- [ ] PIN setup works on first disable attempt
- [ ] PIN verification prevents unauthorized disabling
- [ ] Kids Mode filters species suggestions correctly
- [ ] Quests track progress accurately
- [ ] Quest completion shows celebration message
- [ ] Camera UI shows kid-friendly overlay in Kids Mode
- [ ] Journal Quests tab displays progress correctly
- [ ] Map markers hidden in Kids Mode
- [ ] All three pages respect Kids Mode setting
- [ ] Settings persist across app restarts
