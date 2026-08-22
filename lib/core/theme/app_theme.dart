import 'dart:ui';

import 'package:flutter/material.dart';

/// Centralized colors for price movement so every screen (Watchlist,
/// Market Overview, Holdings, Buy/Sell ticket) flashes and colors numbers
/// identically.
class MarketColors {
  MarketColors._();

  static const Color up = Color(0xFF0E8A45);
  static const Color down = Color(0xFFD1332F);
  static const Color neutral = Color(0xFF6B7280);

  static const Color upFlash = Color(0x5534C266);
  static const Color downFlash = Color(0x55F14848);

  static Color forChange(bool isUp, {required bool isFlat}) {
    if (isFlat) return neutral;
    return isUp ? up : down;
  }
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorSchemeSeed: const Color(0xFF1B4D8C),
      brightness: Brightness.light,
    );
    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFFF6F7F9),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      // Built via copyWith on the base theme's own cardTheme (rather than
      // constructing `CardThemeData`/`CardTheme` by name) so this compiles
      // unchanged across the Flutter versions that renamed that class.
      cardTheme: base.cardTheme.copyWith(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.black.withOpacity(0.06)),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      colorSchemeSeed: const Color(0xFF6FA8DC),
      brightness: Brightness.dark,
    );
    return base.copyWith(
      appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
    );
  }
}

/// Monospaced-ish number style so price columns align visually as digits
/// change every tick -- important for a dense, flicker-free feel.
const TextStyle priceTextStyle = TextStyle(
  fontFeatures: [FontFeature.tabularFigures()],
  fontWeight: FontWeight.w600,
);
