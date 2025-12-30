# Theming and UI Customization Guide

This document explains how to customize the UI elements for the coin economy and trading system in InsectQuest.

## Overview

The economy system uses placeholder icons and colors that can be easily customized to match your desired theme. All UI elements are designed to be swapped without changing core functionality.

## Coin Badges and Icons

### Current Implementation

The coin system uses the following Material Icons:
- `Icons.monetization_on` - Main coin icon (amber color)
- `Icons.account_balance_wallet` - Wallet/economy icon

These appear in:
- Journal page (showing coins earned per capture)
- Economy page (showing balance)
- Camera page (showing coins earned notification)
- Trading page (showing coin amounts in trades)

### How to Customize

#### Option 1: Change Icon Colors

Edit the relevant page files to change colors:

**Journal Page** (`lib/pages/journal_page.dart`, line ~85):
```dart
const Icon(Icons.monetization_on, size: 14, color: Colors.amber),
```

**Economy Page** (`lib/pages/economy_page.dart`, lines 69-72):
```dart
const Icon(
  Icons.account_balance_wallet,
  size: 64,
  color: Colors.amber, // Change this
),
```

**Trading Page** (`lib/pages/trading_page.dart`, lines 263, 268):
```dart
const Icon(Icons.monetization_on, color: Colors.amber, size: 20),
const Icon(Icons.monetization_on, color: Colors.blue, size: 20),
```

#### Option 2: Use Custom Asset Images

Replace Material Icons with custom PNG/SVG assets:

1. Add your coin image to `assets/images/`:
   ```
   assets/
     images/
       coin.png
       coin_large.png
       wallet.png
   ```

2. Update `pubspec.yaml`:
   ```yaml
   flutter:
     assets:
       - assets/catalogs/species_catalog_ga.json
       - assets/images/
   ```

3. Replace `Icon` widgets with `Image.asset`:
   ```dart
   // Instead of:
   const Icon(Icons.monetization_on, size: 14, color: Colors.amber)
   
   // Use:
   Image.asset('assets/images/coin.png', width: 14, height: 14)
   ```

## Trade Status Icons

### Current Implementation

Trade cards show status with these icons:
- `Icons.shopping_bag` - Listed (green)
- `Icons.hourglass_empty` - Pending/In Escrow (orange)
- `Icons.check_circle` - Completed (blue)
- `Icons.cancel` - Cancelled (red)

Located in `lib/pages/trading_page.dart`, line 244.

### How to Customize

Change the icons and colors in the `_buildTradeCard` method:

```dart
Icon(
  trade.status == TradeStatus.listed
      ? Icons.shopping_bag      // Change this
      : trade.status == TradeStatus.pending
          ? Icons.hourglass_empty  // And this
          : trade.status == TradeStatus.completed
              ? Icons.check_circle  // And this
              : Icons.cancel,       // And this
  color: trade.status == TradeStatus.listed
      ? Colors.green              // Change colors
      : ...
)
```

## Color Scheme

### Primary Colors

Economy system uses these colors:
- **Amber** (`Colors.amber`) - Coins, positive actions
- **Blue** (`Colors.blue`) - Completed trades
- **Green** (`Colors.green`) - Available/listed items
- **Orange** (`Colors.orange`) - Pending/waiting
- **Red** (`Colors.red`) - Cancelled/errors

### How to Customize

1. Create a custom color palette in `lib/config/theme.dart`:
   ```dart
   class EconomyColors {
     static const coin = Color(0xFFFFD700); // Gold
     static const success = Color(0xFF00C853); // Bright green
     static const pending = Color(0xFFFFA726); // Orange
     static const cancelled = Color(0xFFE53935); // Red
   }
   ```

2. Import and use throughout the app:
   ```dart
   import '../config/theme.dart';
   
   Icon(Icons.monetization_on, color: EconomyColors.coin)
   ```

## Card Backgrounds and Gradients

### Adding Rarity-based Backgrounds

To add visual flair based on card rarity, modify the Journal page:

```dart
Card(
  margin: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: _getRarityColors(c.tier),
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(12),
  ),
  child: ListTile(...),
)

List<Color> _getRarityColors(String tier) {
  switch (tier) {
    case 'Legendary':
      return [Colors.purple[300]!, Colors.purple[600]!];
    case 'Epic':
      return [Colors.orange[300]!, Colors.orange[600]!];
    case 'Rare':
      return [Colors.blue[300]!, Colors.blue[600]!];
    case 'Uncommon':
      return [Colors.green[300]!, Colors.green[600]!];
    default:
      return [Colors.grey[300]!, Colors.grey[500]!];
  }
}
```

## Escrow Badge Customization

The escrow indicator appears as "⏳ In Escrow" text. To customize:

**Trading Page** (`lib/pages/trading_page.dart`, line 303):
```dart
if (trade.status == TradeStatus.pending)
  const Text(
    '⏳ In Escrow',  // Change emoji and text
    style: TextStyle(fontWeight: FontWeight.bold),
  ),
```

Options:
- `'🔒 Locked'`
- `'⏱️ Processing'`
- `'💼 Holding'`
- Or use an Icon instead:
  ```dart
  Row(
    children: [
      Icon(Icons.lock, size: 16),
      SizedBox(width: 4),
      Text('In Escrow'),
    ],
  )
  ```

## Coin Balance Display

### Economy Page

The large coin balance display can be customized in `lib/pages/economy_page.dart` (lines 65-95):

```dart
// Current: Large amber number with icon
// Customize the size, color, and layout here
Text(
  '${_userProfile?.coins ?? 0}',
  style: const TextStyle(
    fontSize: 48,              // Change size
    fontWeight: FontWeight.bold,
    color: Colors.amber,       // Change color
  ),
),
```

### Add Coin Badge to App Bar

To show coin balance in app bar across all pages:

1. Create a widget in `lib/widgets/coin_badge.dart`:
   ```dart
   class CoinBadge extends StatelessWidget {
     final int coins;
     
     const CoinBadge({required this.coins, super.key});
     
     @override
     Widget build(BuildContext context) {
       return Container(
         padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
         decoration: BoxDecoration(
           color: Colors.amber[700],
           borderRadius: BorderRadius.circular(16),
         ),
         child: Row(
           children: [
             Icon(Icons.monetization_on, size: 16, color: Colors.white),
             SizedBox(width: 4),
             Text(
               '$coins',
               style: TextStyle(
                 color: Colors.white,
                 fontWeight: FontWeight.bold,
               ),
             ),
           ],
         ),
       );
     }
   }
   ```

2. Add to app bars:
   ```dart
   AppBar(
     title: const Text('Journal'),
     actions: [
       FutureBuilder<int>(
         future: _getCoins(),
         builder: (ctx, snapshot) => 
           CoinBadge(coins: snapshot.data ?? 0),
       ),
     ],
   )
   ```

## Typography

### Custom Fonts for Economy

To use a custom font for coin amounts:

1. Add font to `pubspec.yaml`:
   ```yaml
   fonts:
     - family: CoinFont
       fonts:
         - asset: assets/fonts/coin_font.ttf
   ```

2. Use in coin displays:
   ```dart
   Text(
     '${coins}',
     style: TextStyle(
       fontFamily: 'CoinFont',
       fontSize: 48,
       color: Colors.amber,
     ),
   )
   ```

## Animation Ideas

While not implemented in MVP, here are suggestions for future enhancements:

### Coin Earn Animation
```dart
// Add to camera_page.dart after capture
import 'package:flutter/animation.dart';

// Show floating coin animation
showDialog(
  context: context,
  barrierDismissible: true,
  builder: (ctx) => Center(
    child: TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 800),
      builder: (ctx, double value, child) => Transform.scale(
        scale: value,
        child: Icon(
          Icons.monetization_on,
          size: 100,
          color: Colors.amber.withOpacity(value),
        ),
      ),
    ),
  ),
);
```

## Testing Your Changes

After customizing UI elements:

1. Hot reload to see changes: `r` in terminal
2. Hot restart for structural changes: `R` in terminal
3. Test on different screen sizes
4. Verify color contrast for accessibility

## Summary

All economy UI elements are centralized in:
- `lib/pages/economy_page.dart` - Main balance display
- `lib/pages/trading_page.dart` - Trade listings and escrow
- `lib/pages/journal_page.dart` - Coin badges on cards
- `lib/pages/camera_page.dart` - Coin award notifications

Replace icons, colors, and text as needed. The underlying functionality remains unchanged.

For questions, refer to the inline comments in each file.
