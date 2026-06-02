import 'package:flutter/material.dart';

import 'app_theme_tokens.dart';

ThemeData buildAppTheme() {
  const seed = AppThemeTokens.brand;
  final colorScheme =
      ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.light,
      ).copyWith(
        primary: AppThemeTokens.brand,
        onPrimary: Colors.white,
        surface: AppThemeTokens.panel,
        onSurface: AppThemeTokens.text,
        error: AppThemeTokens.dangerText,
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppThemeTokens.workspace,
    dividerTheme: const DividerThemeData(
      color: AppThemeTokens.border,
      space: 1,
      thickness: 1,
    ),
    iconTheme: const IconThemeData(color: AppThemeTokens.mutedText, size: 22),
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        color: AppThemeTokens.headingText,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      titleMedium: TextStyle(
        color: AppThemeTokens.headingText,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      bodyLarge: TextStyle(
        color: AppThemeTokens.text,
        fontSize: 15,
        height: 1.45,
        letterSpacing: 0,
      ),
      bodyMedium: TextStyle(
        color: AppThemeTokens.text,
        fontSize: 14,
        height: 1.45,
        letterSpacing: 0,
      ),
      bodySmall: TextStyle(
        color: AppThemeTokens.mutedText,
        fontSize: 12,
        height: 1.35,
        letterSpacing: 0,
      ),
      labelLarge: TextStyle(
        color: AppThemeTokens.text,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      labelMedium: TextStyle(
        color: AppThemeTokens.mutedText,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
    ),
    tabBarTheme: const TabBarThemeData(
      dividerHeight: 0,
      labelColor: AppThemeTokens.text,
      unselectedLabelColor: AppThemeTokens.mutedText,
      indicatorSize: TabBarIndicatorSize.label,
    ),
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return AppThemeTokens.subtleText;
          }
          return AppThemeTokens.mutedText;
        }),
        minimumSize: const WidgetStatePropertyAll(Size.square(40)),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppThemeTokens.controlRadius),
          ),
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return AppThemeTokens.border;
          }
          if (states.contains(WidgetState.pressed)) {
            return AppThemeTokens.brandPressed;
          }
          return AppThemeTokens.brand;
        }),
        foregroundColor: const WidgetStatePropertyAll(Colors.white),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppThemeTokens.controlRadius),
          ),
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppThemeTokens.panel,
      selectedColor: AppThemeTokens.selected,
      disabledColor: AppThemeTokens.workspace,
      side: const BorderSide(color: AppThemeTokens.border),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      labelStyle: const TextStyle(
        color: AppThemeTokens.mutedText,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      secondaryLabelStyle: const TextStyle(
        color: AppThemeTokens.brandPressed,
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppThemeTokens.controlRadius),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: AppThemeTokens.panel,
      elevation: 8,
      shadowColor: AppThemeTokens.shadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppThemeTokens.radius),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppThemeTokens.panel,
      hintStyle: const TextStyle(color: AppThemeTokens.subtleText),
      prefixIconColor: AppThemeTokens.mutedText,
      suffixStyle: const TextStyle(
        color: AppThemeTokens.subtleText,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppThemeTokens.radius),
        borderSide: const BorderSide(color: AppThemeTokens.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppThemeTokens.radius),
        borderSide: const BorderSide(color: AppThemeTokens.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppThemeTokens.radius),
        borderSide: const BorderSide(color: seed, width: 1.4),
      ),
    ),
  );
}
