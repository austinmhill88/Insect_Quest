import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';
import '../models/trade.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _usersCollection = 'users';
  static const String _tradesCollection = 'trades';

  // User Profile Operations
  Future<UserProfile> getUserProfile(String userId) async {
    final doc = await _firestore.collection(_usersCollection).doc(userId).get();
    if (doc.exists) {
      return UserProfile.fromJson(doc.data()!);
    } else {
      // Create new user profile
      final newProfile = UserProfile(
        userId: userId,
        coins: 0,
        lastUpdated: DateTime.now(),
      );
      await _firestore.collection(_usersCollection).doc(userId).set(newProfile.toJson());
      return newProfile;
    }
  }

  Future<void> updateUserCoins(String userId, int coins) async {
    await _firestore.collection(_usersCollection).doc(userId).update({
      'coins': coins,
      'lastUpdated': DateTime.now().toIso8601String(),
    });
  }

  Future<void> addCoins(String userId, int amount) async {
    final profile = await getUserProfile(userId);
    await updateUserCoins(userId, profile.coins + amount);
  }

  Future<void> deductCoins(String userId, int amount) async {
    final profile = await getUserProfile(userId);
    final newAmount = profile.coins - amount;
    if (newAmount < 0) {
      throw Exception('Insufficient coins');
    }
    await updateUserCoins(userId, newAmount);
  }

  // Trade Operations
  Future<String> createTrade(Trade trade) async {
    final docRef = await _firestore.collection(_tradesCollection).add(trade.toJson());
    return docRef.id;
  }

  Future<Trade?> getTrade(String tradeId) async {
    final doc = await _firestore.collection(_tradesCollection).doc(tradeId).get();
    if (doc.exists) {
      return Trade.fromJson({...doc.data()!, 'id': doc.id});
    }
    return null;
  }

  Future<List<Trade>> listAvailableTrades() async {
    final snapshot = await _firestore
        .collection(_tradesCollection)
        .where('status', isEqualTo: TradeStatus.listed.name)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => Trade.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  Future<List<Trade>> getUserTrades(String userId) async {
    final snapshot = await _firestore
        .collection(_tradesCollection)
        .where('offeredByUserId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => Trade.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  Future<void> updateTradeStatus(String tradeId, TradeStatus status,
      {String? acceptedByUserId}) async {
    final updateData = {
      'status': status.name,
    };
    if (acceptedByUserId != null) {
      updateData['acceptedByUserId'] = acceptedByUserId;
      updateData['acceptedAt'] = DateTime.now().toIso8601String();
    }
    await _firestore.collection(_tradesCollection).doc(tradeId).update(updateData);
  }

  Future<void> acceptTrade(String tradeId, String acceptingUserId) async {
    final trade = await getTrade(tradeId);
    if (trade == null) throw Exception('Trade not found');
    if (trade.status != TradeStatus.listed) throw Exception('Trade not available');

    // Start transaction for atomic updates
    await _firestore.runTransaction((transaction) async {
      // Lock coins in escrow (deduct from accepting user)
      if (trade.coinsRequested > 0) {
        final acceptingUserDoc = _firestore.collection(_usersCollection).doc(acceptingUserId);
        final acceptingUserSnapshot = await transaction.get(acceptingUserDoc);
        final acceptingUserCoins = acceptingUserSnapshot.data()?['coins'] ?? 0;
        if (acceptingUserCoins < trade.coinsRequested) {
          throw Exception('Insufficient coins');
        }
        transaction.update(acceptingUserDoc, {
          'coins': acceptingUserCoins - trade.coinsRequested,
          'lastUpdated': DateTime.now().toIso8601String(),
        });
      }

      // Update trade status
      final tradeDoc = _firestore.collection(_tradesCollection).doc(tradeId);
      transaction.update(tradeDoc, {
        'status': TradeStatus.pending.name,
        'acceptedByUserId': acceptingUserId,
        'acceptedAt': DateTime.now().toIso8601String(),
      });
    });
  }

  Future<void> completeTrade(String tradeId) async {
    final trade = await getTrade(tradeId);
    if (trade == null) throw Exception('Trade not found');
    if (trade.status != TradeStatus.pending) throw Exception('Trade not in pending state');

    // Transfer coins and complete trade
    await _firestore.runTransaction((transaction) async {
      // Transfer coins from offering user to accepting user
      if (trade.coinsOffered > 0 && trade.acceptedByUserId != null) {
        final offeringUserDoc = _firestore.collection(_usersCollection).doc(trade.offeredByUserId);
        final acceptingUserDoc = _firestore.collection(_usersCollection).doc(trade.acceptedByUserId!);

        final offeringUserSnapshot = await transaction.get(offeringUserDoc);
        final acceptingUserSnapshot = await transaction.get(acceptingUserDoc);

        final offeringUserCoins = offeringUserSnapshot.data()?['coins'] ?? 0;
        final acceptingUserCoins = acceptingUserSnapshot.data()?['coins'] ?? 0;

        transaction.update(offeringUserDoc, {
          'coins': offeringUserCoins - trade.coinsOffered + trade.coinsRequested,
          'lastUpdated': DateTime.now().toIso8601String(),
        });

        transaction.update(acceptingUserDoc, {
          'coins': acceptingUserCoins + trade.coinsOffered,
          'lastUpdated': DateTime.now().toIso8601String(),
        });
      }

      // Mark trade as completed
      final tradeDoc = _firestore.collection(_tradesCollection).doc(tradeId);
      transaction.update(tradeDoc, {
        'status': TradeStatus.completed.name,
      });
    });
  }

  Future<void> cancelTrade(String tradeId) async {
    final trade = await getTrade(tradeId);
    if (trade == null) throw Exception('Trade not found');

    // Refund coins if trade was pending
    if (trade.status == TradeStatus.pending && trade.acceptedByUserId != null && trade.coinsRequested > 0) {
      await addCoins(trade.acceptedByUserId!, trade.coinsRequested);
    }

    await updateTradeStatus(tradeId, TradeStatus.cancelled);
  }
}
