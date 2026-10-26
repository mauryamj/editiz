import 'package:flutter/material.dart';

// Class: theme definitions and custom colors for editiz.
abstract final class AppTheme {
  // Constant: primary violet brand color.
  static const Color primaryViolet = Color(0xFF6C4CF5);

  // Constant: save button coral color.
  static const Color saveCoral = Color(0xFFFF7A59);

  // Constant: success and accent teal color.
  static const Color successTeal = Color(0xFF00B8A9);

  // Constant: dark surface and container tones.
  static const Color darkBackground = Color(0xFF121018);
  static const Color darkSurfaceContainer = Color(0xFF1E1A29);

  // Static method: dark theme data configured for Material 3 Expressive (~80%).
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryViolet,
      brightness: Brightness.dark,
    ).copyWith(surface: darkBackground, surfaceContainer: darkSurfaceContainer);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: darkBackground,
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        elevation: 0,
        color: darkSurfaceContainer,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 56),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        indicatorShape: StadiumBorder(),
        height: 72,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
    );
  }
}
