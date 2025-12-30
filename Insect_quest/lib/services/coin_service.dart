import 'package:shared_preferences/shared_preferences.dart';

class CoinService {
  static const _coinsKey = "coins";

  // Get current coin balance
  static Future<int> getCoins() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt(_coinsKey) ?? 0;
  }

  // Add coins to balance
  static Future<int> addCoins(int amount) async {
    final current = await getCoins();
    final newBalance = current + amount;
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_coinsKey, newBalance);
    return newBalance;
  }

  // Spend coins (returns true if successful, false if insufficient balance)
  static Future<bool> spendCoins(int amount) async {
    final current = await getCoins();
    if (current < amount) return false;
    
    final newBalance = current - amount;
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_coinsKey, newBalance);
    return true;
  }

  // Set coin balance (for testing or admin purposes)
  static Future<void> setCoins(int amount) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_coinsKey, amount);
  }
}
