import 'package:flutter/material.dart';

class OrbitTheme {
  const OrbitTheme._();

  static ThemeData dark() {
    const seed = Color(0xFF8EA7FF);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.black,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.dark,
      ).copyWith(
        surface: Colors.black,
        onSurface: const Color(0xFFE8ECFF),
      ),
      textTheme: Typography.whiteMountainView.apply(
        bodyColor: const Color(0xFFE8ECFF),
        displayColor: const Color(0xFFE8ECFF),
      ),
    );
  }
}
