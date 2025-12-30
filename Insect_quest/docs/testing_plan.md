# Manual Testing Plan for Coin Economy & Trading

This document outlines manual tests to verify the coin economy and trading system implementation.

## Prerequisites

Before testing:
- [ ] App builds successfully: `flutter run`
- [ ] Firebase configured (or accepting that Economy/Trading will show errors without it)
- [ ] Device has camera and location permissions
- [ ] At least 2 test devices/emulators for trading tests (or use mock data)

## Test Suite

### 1. Coin Earning on Capture

**Goal**: Verify coins are awarded when minting a card (capturing an insect)

**Steps**:
1. Launch app
2. Navigate to Capture tab
3. Capture an insect (any quality)
4. Note the snackbar message showing "+X pts, +Y coins"
5. Navigate to Journal tab
6. Verify the capture shows both points and coin amount

**Expected Results**:
- ✅ Snackbar shows both points and coins
- ✅ Journal entry displays coin icon with amount
- ✅ Coin amount varies based on rarity and quality
- ✅ Common: ~50 coins, Legendary: ~1500 coins

**Test Cases**:
- [ ] Common tier capture
- [ ] Rare tier capture  
- [ ] Legendary tier capture (Georgia state species)
- [ ] Low quality photo (<0.9) - lower coins
- [ ] High quality photo (>1.0) - higher coins

---

### 2. Economy Page - Coin Balance Display

**Goal**: Verify Economy page shows coin balance

**Steps**:
1. Launch app
2. Navigate to Economy tab (wallet icon)
3. Observe coin balance display

**Expected Results** (with Firebase):
- ✅ Large coin icon with balance number
- ✅ Last updated timestamp
- ✅ "How to earn coins" info card
- ✅ "Trading" navigation button
- ✅ Refresh button in app bar works

**Expected Results** (without Firebase):
- ✅ Error message displayed
- ✅ Retry button available
- ✅ App doesn't crash

**Test Cases**:
- [ ] Fresh install (0 coins)
- [ ] After capturing 1 insect
- [ ] After capturing 5 insects
- [ ] Pull to refresh updates balance
- [ ] Tap refresh button updates balance

---

### 3. Firebase Synchronization

**Goal**: Verify coins sync to Firestore cloud storage

**Requires**: Firebase configured

**Steps**:
1. Capture an insect
2. Note coin amount awarded
3. Navigate to Economy tab
4. Verify balance increased
5. Open Firebase Console → Firestore
6. Check `users/{userId}` document
7. Verify `coins` field matches app display

**Expected Results**:
- ✅ Firestore document created with userId
- ✅ Coins field matches app balance
- ✅ lastUpdated timestamp is recent
- ✅ Balance persists after app restart

**Test Cases**:
- [ ] First capture creates user profile
- [ ] Subsequent captures increment coins
- [ ] Restart app - balance persists
- [ ] Offline capture - syncs when online

---

### 4. Trading - Create Listing

**Goal**: Verify user can create a trade listing

**Steps**:
1. Capture at least 1 insect (to have a card)
2. Navigate to Economy tab
3. Tap "Trading" button or navigate to Trading page
4. Tap FAB "Create Trade" button
5. Select a capture from dropdown
6. Enter coins offered: 10
7. Enter coins requested: 20
8. Tap "List"

**Expected Results**:
- ✅ Dialog shows all available captures
- ✅ Can input coin amounts
- ✅ "List" button creates trade
- ✅ Success snackbar appears
- ✅ Trade appears in "My Trades" tab
- ✅ Trade status shows "LISTED"

**Test Cases**:
- [ ] List with 0 coins offered/requested
- [ ] List with only coins offered
- [ ] List with only coins requested
- [ ] List with both coins offered and requested
- [ ] Cancel dialog - no trade created

---

### 5. Trading - View Available Trades

**Goal**: Verify user can see other players' trade listings

**Steps**:
1. Navigate to Trading page
2. Switch to "Available" tab
3. Observe trade listings

**Expected Results** (with trades):
- ✅ List of trade cards displayed
- ✅ Each card shows:
  - Card ID preview
  - Coins offered (amber icon)
  - Coins requested (blue icon)
  - Listed timestamp
  - Status chip (LISTED)
  - Accept button
- ✅ Pull to refresh works

**Expected Results** (no trades):
- ✅ Empty state with cart icon
- ✅ "No trades available" message

**Test Cases**:
- [ ] Empty state (no trades)
- [ ] Single trade listed
- [ ] Multiple trades listed
- [ ] Scroll through long list

---

### 6. Trading - Accept Trade

**Goal**: Verify escrow system locks coins when accepting trade

**Requires**: 
- Another user's trade listing
- Sufficient coins for requested amount

**Steps**:
1. Navigate to Trading → Available tab
2. Tap "Accept" on a trade requesting X coins
3. Review confirmation dialog
4. Tap "Accept" to confirm
5. Check Economy tab balance

**Expected Results**:
- ✅ Confirmation dialog shows coin amounts
- ✅ After accepting, trade moves to "PENDING" status
- ✅ Requested coins deducted from balance
- ✅ Trade shows "⏳ In Escrow" indicator
- ✅ Cannot accept if insufficient coins

**Test Cases**:
- [ ] Accept with exact coin amount
- [ ] Accept with more than needed coins
- [ ] Try to accept with insufficient coins (should fail)
- [ ] Accept 0-coin trade
- [ ] Balance updates immediately

---

### 7. Trading - Cancel Trade

**Goal**: Verify trade creator can cancel their listing

**Steps**:
1. Create a trade listing (see Test 4)
2. Navigate to "My Trades" tab
3. Find the trade with LISTED status
4. Tap "Cancel" button
5. Confirm cancellation

**Expected Results**:
- ✅ Confirmation dialog appears
- ✅ After confirming, status changes to CANCELLED
- ✅ Trade no longer in Available tab
- ✅ If trade was pending, escrowed coins refunded

**Test Cases**:
- [ ] Cancel listed trade
- [ ] Cancel pending trade (coins refunded)
- [ ] Cannot cancel completed trade
- [ ] Cannot cancel already cancelled trade

---

### 8. Trading - My Trades View

**Goal**: Verify user can see their own trade history

**Steps**:
1. Create 2-3 trades (some listed, some accepted/cancelled)
2. Navigate to Trading → My Trades tab
3. Observe list

**Expected Results**:
- ✅ All user's trades displayed (listed, pending, completed, cancelled)
- ✅ Status chips color-coded:
  - Green = LISTED
  - Orange = PENDING
  - Blue = COMPLETED
  - Red = CANCELLED
- ✅ Can cancel LISTED trades
- ✅ Cannot cancel non-listed trades
- ✅ Trade details visible (coins, timestamps)

**Test Cases**:
- [ ] Empty state (no trades)
- [ ] Only listed trades
- [ ] Mix of different statuses
- [ ] Cancel a listed trade

---

### 9. UI - Coin Badges

**Goal**: Verify coin icons appear throughout UI

**Steps**:
1. Capture insects to earn coins
2. Check each page for coin displays

**Expected Results**:
- ✅ **Journal page**: Coin icon + amount per capture
- ✅ **Economy page**: Large balance display
- ✅ **Trading page**: Coin amounts in trade cards
- ✅ **Camera page**: Snackbar shows coins awarded
- ✅ All icons use amber/gold color
- ✅ Icons consistent across app

**Test Cases**:
- [ ] Journal shows coin badge for each capture
- [ ] Economy shows large coin balance
- [ ] Trading shows offered/requested coins clearly
- [ ] Snackbar notification shows coins

---

### 10. Offline Behavior

**Goal**: Verify graceful degradation without Firebase

**Steps**:
1. Disable Firebase or network
2. Launch app
3. Try to access Economy tab
4. Try to access Trading tab
5. Capture an insect

**Expected Results**:
- ✅ Economy tab shows error message
- ✅ Trading tab shows error message
- ✅ Capture still works normally
- ✅ Journal still shows coin amounts (stored locally)
- ✅ No app crashes
- ✅ When network restored, data syncs

**Test Cases**:
- [ ] No Firebase configured - error shown
- [ ] Airplane mode - error shown
- [ ] Offline capture - coins tracked locally
- [ ] Come back online - data syncs

---

### 11. Edge Cases

**Goal**: Test boundary conditions and error handling

**Test Cases**:

#### Balance Tests
- [ ] Zero balance - can view Economy page
- [ ] Zero balance - cannot accept trades requiring coins
- [ ] Large balance (10,000+ coins) - displays correctly
- [ ] Negative balance prevented (should never happen)

#### Trade Tests
- [ ] Trade with 0 coins offered and requested - allowed
- [ ] Trade with very large coin amounts - displays correctly
- [ ] Delete app data - user profile recreates
- [ ] Multiple rapid accepts (race condition) - only one succeeds

#### Capture Tests
- [ ] Capture same species multiple times - each awards coins
- [ ] Capture Legendary with perfect quality - maximum coins
- [ ] Capture Common with poor quality - minimum coins

---

## Integration Tests

### End-to-End Trade Flow

**Goal**: Complete full trade cycle between two users

**Requires**: 2 devices or 2 user accounts

**Steps**:
1. **Device A**: Capture insects, earn 100 coins
2. **Device A**: Create trade listing (offer Card X, request 50 coins)
3. **Device B**: Capture insects, earn 100 coins
4. **Device B**: View Available trades, see Device A's listing
5. **Device B**: Accept trade (50 coins locked in escrow)
6. **Device B**: Balance shows -50 coins deducted
7. **Device A**: (Simulate completion) Trade completes
8. **Device A**: Receives 50 coins from Device B
9. **Device B**: Receives Card X from Device A
10. Both devices: Verify balances updated correctly

**Expected Results**:
- ✅ Trade listed by A appears for B
- ✅ B's coins locked when accepting
- ✅ Trade shows PENDING status
- ✅ Upon completion, coins and cards transferred
- ✅ Firestore reflects final state
- ✅ Both users see correct balances

---

## Theming Verification

**Goal**: Verify UI is easily customizable per docs

**Steps**:
1. Follow `docs/theming.md` instructions
2. Change coin icon color to red
3. Hot reload app
4. Verify change appears throughout app

**Expected Results**:
- ✅ Docs clearly explain customization
- ✅ Changes applied with hot reload
- ✅ Icons update consistently
- ✅ No functionality broken

---

## Performance Tests

**Goal**: Verify app remains responsive with many trades/captures

**Test Cases**:
- [ ] 100+ captures in Journal - smooth scrolling
- [ ] 50+ trades in Trading page - smooth scrolling
- [ ] Large coin balance (1,000,000+) - displays correctly
- [ ] Rapid coin earning (10 captures quickly) - all synced

---

## Summary Checklist

### Core Features
- [ ] Coins awarded on capture
- [ ] Coin amounts based on rarity and quality
- [ ] Economy page displays balance
- [ ] Firebase sync works (if configured)
- [ ] Trading page lists trades
- [ ] Can create trade listing
- [ ] Can accept trade (escrow)
- [ ] Can cancel trade
- [ ] UI shows coin badges throughout

### Error Handling
- [ ] Works offline (graceful errors)
- [ ] Handles insufficient coins
- [ ] Handles missing Firebase
- [ ] No crashes during testing

### Documentation
- [ ] Firebase setup docs clear
- [ ] Theming docs helpful
- [ ] README updated with economy info

### Polish
- [ ] Icons consistent (amber coins)
- [ ] Status colors correct (green/orange/blue/red)
- [ ] Loading states shown
- [ ] Error messages helpful
- [ ] Success feedback (snackbars)

---

## Known Limitations (MVP)

This is an MVP implementation. The following are expected limitations:

- No authentication - user ID is device-based
- No actual card transfer - only coin transfers implemented
- No trade completion button - manual/automatic completion not implemented
- No trade search/filter
- No trade history beyond status
- No push notifications for trade status changes
- Test mode Firestore rules (insecure for production)
- No rate limiting or abuse prevention

These are documented as future enhancements and acceptable for MVP testing.

---

## Reporting Issues

If tests fail, document:
1. Device/emulator used
2. Flutter version: `flutter --version`
3. Firebase configured: Yes/No
4. Steps to reproduce
5. Expected vs actual behavior
6. Screenshots if UI issue
7. Logs: `flutter logs | grep -i error`

---

**Testing complete!** ✅

Once all tests pass, the coin economy and trading system MVP is ready for user feedback.
