import 'package:flutter/material.dart';

/// Utility class for rarity-related UI elements
class RarityUtils {
  /// Returns the color associated with a rarity tier
  static Color getRarityColor(String tier) {
    switch (tier) {
      case 'Common':
        return Colors.grey;
      case 'Uncommon':
        return Colors.green;
      case 'Rare':
        return Colors.blue;
      case 'Epic':
        return Colors.purple;
      case 'Legendary':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  /// Returns the icon associated with a rarity tier
  static IconData getRarityIcon(String tier) {
    switch (tier) {
      case 'Common':
        return Icons.circle;
      case 'Uncommon':
        return Icons.album;
      case 'Rare':
        return Icons.hexagon;
      case 'Epic':
        return Icons.stars;
      case 'Legendary':
        return Icons.auto_awesome;
      default:
        return Icons.circle;
    }
  }
}
