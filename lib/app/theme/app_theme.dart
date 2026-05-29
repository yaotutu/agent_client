import 'package:flutter/material.dart';

import 'app_theme_tokens.dart';

ThemeData buildAppTheme() {
  const seed = AppThemeTokens.brand;

  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: seed),
    scaffoldBackgroundColor: AppThemeTokens.workspace,
    tabBarTheme: const TabBarThemeData(
      dividerHeight: 0,
      labelColor: AppThemeTokens.text,
      unselectedLabelColor: AppThemeTokens.mutedText,
      indicatorSize: TabBarIndicatorSize.label,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppThemeTokens.panel,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppThemeTokens.radius),
        borderSide: const BorderSide(color: AppThemeTokens.strongBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppThemeTokens.radius),
        borderSide: const BorderSide(color: AppThemeTokens.strongBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppThemeTokens.radius),
        borderSide: const BorderSide(color: seed, width: 1.4),
      ),
    ),
  );
}
