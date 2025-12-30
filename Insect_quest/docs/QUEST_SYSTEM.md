# Quest System Documentation

## Overview

The InsectQuest app now features a comprehensive quest, streak, and achievement system that encourages daily engagement and rewards players for their exploration efforts.

## System Components

### 1. Quest System

#### Quest Types
- **captureAny**: Capture any insect
- **captureGroup**: Capture insects from specific groups (e.g., Butterflies, Bees/Wasps)
- **captureTier**: Capture insects of a specific rarity tier
- **captureSpecific**: Capture a specific species
- **captureCount**: Capture a certain number of insects
- **captureQuality**: Capture insects with quality above a threshold

#### Quest Periods
- **Daily Quests**: Reset every day at midnight (3 quests generated)
- **Weekly Quests**: Reset every Monday (2 quests generated)

#### Quest Lifecycle
1. **Generation**: Quests are auto-generated at app start if needed
2. **Progress**: Each capture is checked against active quests
3. **Completion**: When progress reaches target, quest is marked complete
4. **Claiming**: User must claim the reward to receive coins/foils
5. **Expiration**: Unclaimed rewards expire with the quest period

#### Sample Quests

**Daily:**
- "Daily Explorer" - Photograph any insect (50 coins)
- "Pollinator Patrol" - Capture 2 pollinators (75 coins)
- "Urban Hunter" - Find 3 insects in urban areas (100 coins)

**Weekly:**
- "Diversity Champion" - Capture 5 different species groups (250 coins + foil chance)
- "Quality Photographer" - Capture 3 insects with quality > 1.0 (200 coins)

### 2. Streak System

#### How It Works
- Tracks consecutive days of insect captures
- Increments when capturing on a new day
- Resets to 1 if a day is skipped
- Maintains "longest streak" record

#### Streak Display
- Current streak shown in Journal profile stats
- Fire emoji (🔥) indicates active streak
- Clickable to view detailed streak information
- Shows last activity date

### 3. Achievement System

#### Achievement Categories

**Set Completion**
- Complete all species in a catalog group
- Examples: "Butterfly Collector", "Bee Keeper", "Spider Expert"

**Milestones**
- Reach specific capture counts
- Examples: "First Capture" (1), "Getting Started" (10), "Dedicated Collector" (50), "Master Collector" (100)

**Streaks**
- Maintain daily exploration streaks
- Examples: "Weekly Explorer" (7 days), "Monthly Explorer" (30 days)

**Region/Habitat**
- Capture in specific locations
- Example: "Urban Explorer" (20 urban captures)

#### Achievement Lifecycle
1. **Initialization**: Default achievements loaded on first app start
2. **Checking**: After each capture, all unlocked achievements are checked
3. **Unlocking**: When criteria met, achievement is marked unlocked with timestamp
4. **Rewards**: Coin rewards automatically added to balance
5. **Display**: Unlocked achievements shown in Journal achievements dialog

### 4. Currency System

#### Coins
- Primary in-app currency
- Earned through:
  - Quest completion
  - Achievement unlocks
  - (Future: Trading, events)

#### Coin Balance
- Displayed in Quests page header
- Displayed in Journal profile stats
- Persists across app sessions

## User Interface

### Quests Page
- Accessible via bottom navigation (🏆 icon)
- Shows coin balance in header
- Daily quests section with countdown timer
- Weekly quests section
- Progress bars for each quest
- "Claim Reward" button for completed quests
- Visual indicators for expired quests

### Journal Page Enhancements
- **Profile Stats Card**:
  - Total captures count
  - Current coin balance (💰)
  - Current streak (🔥)
  - Achievement progress (🏆)
  
- **Interactive Stats**:
  - Click streak → Streak details dialog
  - Click achievements → Achievement list dialog
  - Trophy icon in app bar → Achievement list

### Capture Flow Integration
- After capturing an insect:
  1. Quest progress updated automatically
  2. Streak checked and updated if new day
  3. Achievements checked for unlocks
  4. Snackbar notification shows:
     - Points earned
     - Quest completions
     - Streak count
     - Achievement unlocks
  5. Detailed rewards dialog if quest/achievement completed

## Technical Implementation

### Data Models
- `Quest`: id, title, description, type, period, requirements, rewards, progress, target, expiration
- `Streak`: currentStreak, longestStreak, lastActivityDate
- `Achievement`: id, title, description, type, criteria, coinReward, unlocked, unlockedAt

### Services
- `QuestService`: Quest generation, progress tracking, reward claiming, cleanup
- `StreakService`: Streak increment, reset detection, persistence
- `AchievementService`: Achievement checking, unlocking, persistence
- `CoinService`: Balance management, earning, spending

### Storage
All data persists locally using SharedPreferences:
- Quests: `"quests"` key
- Streak: `"streak"` key
- Achievements: `"achievements"` key
- Coins: `"coins"` key
- Last quest refresh: `"last_quest_refresh"` key

## Future Enhancements

### Potential Quest Types
- Nocturnal quests (time-based)
- Weather-specific quests
- Social quests (share captures)
- Combo quests (multiple requirements)

### Potential Achievements
- Rarity achievements (capture all Legendary)
- Speed achievements (X captures in Y minutes)
- Location achievements (visit X different geocells)
- Photography achievements (quality thresholds)

### Potential Features
- Quest reroll (spend coins to get new quest)
- Achievement showcase in profile
- Leaderboards for streaks
- Quest history and statistics
- Push notifications for quest expiration

## Testing Recommendations

### Manual Testing Checklist
1. ✅ Verify quest generation on app start
2. ✅ Complete a daily quest and claim reward
3. ✅ Capture insects on consecutive days to build streak
4. ✅ Skip a day and verify streak resets
5. ✅ Unlock an achievement (e.g., first capture)
6. ✅ View achievements dialog
7. ✅ View streak details dialog
8. ✅ Check coin balance updates after claiming rewards
9. ✅ Verify quest progress updates correctly
10. ✅ Test quest expiration (mock time if needed)

### Edge Cases to Test
- Multiple captures in same day (streak shouldn't increment twice)
- App restart preserves all progress
- Quest progress for unique groups (diversity quest)
- Achievement unlock only fires once
- Expired quests are cleaned up properly
