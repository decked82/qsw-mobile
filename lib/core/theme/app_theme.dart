import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const Color seedColor = Colors.blue;
  static const Color scaffoldBackgroundColor = Color(0xFFF5F7FA);
  static const double inputBorderRadius = 8;

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputBorderRadius),
        ),
      ),
    );
  }
}
