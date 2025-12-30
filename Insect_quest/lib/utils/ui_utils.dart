import 'package:flutter/material.dart';

/// UI utility functions for the app.
class UIUtils {
  /// Returns the color associated with a rarity tier.
  /// 
  /// Used for displaying tier badges and indicators throughout the app.
  static Color getTierColor(String tier) {
    switch (tier) {
      case 'Legendary':
        return Colors.purple;
      case 'Epic':
        return Colors.deepPurple;
      case 'Rare':
        return Colors.blue;
      case 'Uncommon':
        return Colors.green;
      case 'Common':
      default:
        return Colors.grey;
    }
  }
}
