import 'package:flutter/material.dart';

/// Verde Habitly — Material 3, limpo e moderno.
const habitlyGreen = Color(0xFF1B7A4B);
const habitlySeed = Color(0xFF2E7D32);

const habitColorPalette = <Color>[
  Color(0xFF2E7D32),
  Color(0xFF00796B),
  Color(0xFF0277BD),
  Color(0xFF6A1B9A),
  Color(0xFFC62828),
  Color(0xFFEF6C00),
  Color(0xFFF9A825),
  Color(0xFF455A64),
];

const habitIconOptions = <String>[
  '🌱',
  '🏃',
  '📚',
  '💧',
  '🧘',
  '💊',
  '🥗',
  '😴',
  '✍️',
  '🧹',
  '🚶',
  '🎯',
  '❤️',
  '🎵',
  '☀️',
  '🧠',
];

ThemeData buildHabitlyTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: habitlySeed,
    brightness: Brightness.light,
  ).copyWith(primary: habitlyGreen);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 1,
    ),
    navigationBarTheme: NavigationBarThemeData(
      elevation: 0,
      height: 72,
      indicatorColor: scheme.secondaryContainer,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        );
      }),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 52),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 24),
  );
}
