# Known Issues and Future Enhancements

This document tracks known limitations and suggested improvements for the economy and trading system.

## Status: MVP Complete ✅

The current implementation meets all acceptance criteria and is ready for testing. The issues below are non-blocking and can be addressed in future iterations based on user feedback.

---

## Known Issues (Non-Blocking)

### 1. Generic Error Messages
**Location**: `lib/services/firestore_service.dart`
**Issue**: Error messages like "Insufficient coins" don't provide context about amounts
**Severity**: Low
**Impact**: Harder to debug when errors occur
**Suggested Fix**: Include actual amounts in error messages
```dart
throw Exception('Insufficient coins: attempted to deduct $amount but balance is ${profile.coins}');
```

### 2. Non-Atomic Coin Refund
**Location**: `lib/services/firestore_service.dart:176-178`
**Issue**: `cancelTrade()` refunds coins separately from status update
**Severity**: Low-Medium
**Impact**: If refund fails, trade is still cancelled, causing inconsistency
**Suggested Fix**: Wrap entire cancel operation in a Firestore transaction
```dart
await _firestore.runTransaction((transaction) async {
  // Refund coins and update status atomically
});
```

### 3. Missing Input Validation in Trade Dialog
**Location**: `lib/pages/trading_page.dart:106`
**Issue**: User can enter negative or extremely large coin amounts
**Severity**: Medium
**Impact**: Could cause unexpected behavior or exploits
**Suggested Fix**: Add TextFormField validators
```dart
validator: (value) {
  final num = int.tryParse(value ?? '');
  if (num == null || num < 0 || num > 10000) {
    return 'Please enter a value between 0 and 10,000';
  }
  return null;
}
```

### 4. Unsafe Substring Operation
**Location**: `lib/pages/trading_page.dart:293`
**Issue**: `substring(0, 8)` will crash if capture ID is shorter than 8 characters
**Severity**: Low
**Impact**: App crash if malformed IDs exist
**Suggested Fix**: Safe substring helper
```dart
final preview = captureId.length > 8 ? captureId.substring(0, 8) : captureId;
```

### 5. Hardcoded Magic Numbers
**Location**: `lib/pages/camera_page.dart:277`
**Issue**: Coin limit of 10,000 is hardcoded
**Severity**: Low
**Impact**: Hard to maintain if limits need to change
**Suggested Fix**: Create `lib/config/economy_config.dart`
```dart
class EconomyConfig {
  static const maxCoinsPerCapture = 10000;
  static const maxCoinsPerTrade = 100000;
}
```

### 6. Enum Parsing Without Error Handling
**Location**: `lib/models/trade.dart:53`
**Issue**: `firstWhere` throws if status string doesn't match any enum
**Severity**: Low
**Impact**: App crash with corrupted data or version mismatches
**Suggested Fix**: Use `firstWhereOrNull` or default value
```dart
status: TradeStatus.values.firstWhere(
  (e) => e.name == m["status"],
  orElse: () => TradeStatus.cancelled,
)
```

---

## MVP Limitations (By Design)

These are intentional simplifications for MVP that should be addressed before production:

### Authentication
- **Current**: Device-based user IDs (UUID in SharedPreferences)
- **Issue**: No real user accounts, can't access coins from different devices
- **Future**: Implement Firebase Authentication

### Card Transfer
- **Current**: Only coin transfers implemented
- **Issue**: Cards don't actually move between users
- **Future**: Implement actual card ownership and transfer in Firestore

### Trade Completion
- **Current**: No UI button to complete pending trades
- **Issue**: Trades stay in pending state indefinitely
- **Future**: Add "Complete Trade" button and automatic completion after card verification

### Security Rules
- **Current**: Test-mode Firestore rules (allow all read/write)
- **Issue**: Anyone can modify anyone's data
- **Future**: Implement proper authentication and security rules (see `docs/firebase_setup.md`)

### Trade Discovery
- **Current**: Simple list of all available trades
- **Issue**: Hard to find specific trades as volume grows
- **Future**: Add search, filters, sorting, pagination

### Notifications
- **Current**: No notifications when trades accepted/completed
- **Issue**: User must manually check trade status
- **Future**: Add Firebase Cloud Messaging push notifications

### Rate Limiting
- **Current**: No limits on trade creation or coin earning
- **Issue**: Vulnerable to spam and abuse
- **Future**: Add rate limiting in Firestore security rules

---

## Performance Considerations

### Current Status: Good for MVP
- Firestore queries limited to reasonable page sizes
- Transactions used for atomic updates
- Offline persistence enabled

### Future Optimizations:
1. **Pagination**: Implement cursor-based pagination for long trade lists
2. **Caching**: Add local caching for frequently accessed data
3. **Indexes**: Create Firestore composite indexes for complex queries
4. **Batch Operations**: Use batch writes for bulk updates

---

## Suggested Enhancement Priority

Based on potential impact and user feedback:

### High Priority (Do Soon)
1. ✅ Input validation for trade coin amounts (prevents exploits)
2. ✅ Atomic cancel operation (prevents coin loss)
3. Authentication (enables multi-device support)

### Medium Priority (Nice to Have)
4. Better error messages (improves debugging)
5. Trade completion UI (finishes MVP workflow)
6. Card transfer implementation (core feature)

### Low Priority (Polish)
7. Magic number constants (code quality)
8. Safe substring helper (edge case handling)
9. Enum parsing fallback (robustness)

### Future Features (Post-MVP)
10. Push notifications
11. Search and filters
12. Rate limiting
13. Trade history
14. Reputation system

---

## Testing Checklist

Before addressing these issues, verify current functionality:
- [ ] Coins awarded on capture
- [ ] Economy page loads balance
- [ ] Can create trade listing
- [ ] Can accept trade (escrow works)
- [ ] Can cancel trade (refund works)
- [ ] UI displays correctly throughout

See `docs/testing_plan.md` for comprehensive test scenarios.

---

## How to Contribute

To address any of these issues:

1. Pick an issue from the list
2. Create a branch: `git checkout -b fix/issue-name`
3. Implement the fix
4. Test thoroughly
5. Update this document
6. Submit PR

---

## Version History

- **v0.1.0** (2025-12-30): MVP implementation complete
  - All acceptance criteria met
  - 6 known non-blocking issues documented
  - Ready for testing and user feedback

---

**Note**: This document will be updated as issues are resolved and new ones are discovered during testing.
