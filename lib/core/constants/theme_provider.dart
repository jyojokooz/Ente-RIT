// ===============================
// FILE PATH: lib/core/constants/theme_provider.dart
// ===============================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 1. A provider to hold SharedPreferences synchronously.
/// We will initialize this in main.dart before the app runs.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main.dart',
  );
});

/// 2. The Notifier that manages the ThemeMode state.
class ThemeNotifier extends Notifier<ThemeMode> {
  static const _themeKey = 'isDarkMode';

  @override
  ThemeMode build() {
    // Read the saved theme immediately using our synchronous provider
    final prefs = ref.watch(sharedPreferencesProvider);
    final isDark = prefs.getBool(_themeKey) ?? false;
    return isDark ? ThemeMode.dark : ThemeMode.light;
  }

  void toggleTheme(bool isOn) {
    // Update state to trigger UI rebuild
    state = isOn ? ThemeMode.dark : ThemeMode.light;
    // Save to SharedPreferences securely in the background
    ref.read(sharedPreferencesProvider).setBool(_themeKey, isOn);
  }
}

/// 3. The globally accessible provider for the Theme
final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(
  ThemeNotifier.new,
);
