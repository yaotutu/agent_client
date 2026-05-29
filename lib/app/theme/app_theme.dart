import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
  const seed = Color(0xFF256D85);

  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: seed),
    scaffoldBackgroundColor: const Color(0xFFF7F8FA),
    tabBarTheme: const TabBarThemeData(
      dividerHeight: 0,
      labelColor: Color(0xFF101828),
      unselectedLabelColor: Color(0xFF667085),
      indicatorSize: TabBarIndicatorSize.label,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: seed, width: 1.4),
      ),
    ),
  );
}
