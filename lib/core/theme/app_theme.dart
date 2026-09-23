import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Colors.blueAccent;
  static const Color inactive = Colors.white54;
  static const Color backgroundBlack = Color(0xDE000000);

  static const Duration animationDuration = Duration(milliseconds: 250);
  static const Curve animationCurve = Curves.easeInOutCubic;

  static final ThemeData darkTheme = ThemeData.dark(useMaterial3: true)
      .copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1F1F1F),
          foregroundColor: Colors.white,
        ),
      );

  static final ThemeData lightTheme = ThemeData.light(useMaterial3: true)
      .copyWith(
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 1,
        ),
      );
}
