import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const _forestGreen = Color(0xFF456B5A);
  static const _darkGreen = Color(0xFF294A3B);
  static const _lightSage = Color(0xFFDCE8E0);
  static const _pencilYellow = Color(0xFFE5B84B);
  static const _mutedRed = Color(0xFFB84A4A);
  static const _disabled = Color(0xFFAAB5AE);

  static ThemeData get light {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: _forestGreen,
          brightness: Brightness.light,
        ).copyWith(
          primary: _forestGreen,
          onPrimary: Colors.white,
          primaryContainer: _lightSage,
          onPrimaryContainer: _darkGreen,
          secondary: _pencilYellow,
          onSecondary: const Color(0xFF3B2F0A),
          secondaryContainer: const Color(0xFFF5E5AF),
          onSecondaryContainer: const Color(0xFF3B2F0A),
          error: _mutedRed,
          onError: Colors.white,
        );

    return ThemeData(
      colorScheme: colorScheme,
      fontFamily: 'Nunito',
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.transparent,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? _disabled
                : _forestGreen,
          ),
          foregroundColor: const WidgetStatePropertyAll(Colors.white),
          minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _darkGreen,
          side: const BorderSide(color: _forestGreen, width: 1.5),
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _darkGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
