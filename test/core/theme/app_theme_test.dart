import 'package:civic_scope/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppTheme', () {
    test('light theme exposes expected brightness and primary color', () {
      expect(AppTheme.light.brightness, Brightness.light);
      expect(AppTheme.light.colorScheme.primary, const Color(0xFF388E3C));
    });

    test('dark theme exposes expected brightness and primary color', () {
      expect(AppTheme.dark.brightness, Brightness.dark);
      expect(AppTheme.dark.colorScheme.primary, const Color(0xFF81C784));
    });

    test('warning extension returns mode-specific colors', () {
      expect(
        AppTheme.light.colorScheme.warning,
        const Color.fromARGB(255, 234, 111, 44),
      );
      expect(AppTheme.dark.colorScheme.warning, const Color(0xFFFFB74D));
    });
  });
}
