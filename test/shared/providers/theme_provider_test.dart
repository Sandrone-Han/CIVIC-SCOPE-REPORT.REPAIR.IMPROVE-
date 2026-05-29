import 'package:civic_scope/shared/providers/shared_preferences_provider.dart';
import 'package:civic_scope/shared/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_preferences.dart';

void main() {
  group('themeModeProvider', () {
    test('defaults to system mode when no preference is stored', () async {
      final prefs = await setUpTestPrefs();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      expect(container.read(themeModeProvider), ThemeMode.system);
    });

    test('hydrates stored theme mode from SharedPreferences', () async {
      final prefs = await setUpTestPrefs({'theme_mode': 'dark'});
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      expect(container.read(themeModeProvider), ThemeMode.dark);
    });

    test('setTheme updates provider state and persists to SharedPreferences', () async {
      final prefs = await setUpTestPrefs();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      container.read(themeModeProvider.notifier).setTheme(ThemeMode.light);

      expect(container.read(themeModeProvider), ThemeMode.light);
      expect(prefs.getString('theme_mode'), 'light');
    });
  });
}
