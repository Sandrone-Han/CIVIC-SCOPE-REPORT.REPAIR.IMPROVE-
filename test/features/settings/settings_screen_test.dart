import 'package:civic_scope/core/routing/app_routes.dart';
import 'package:civic_scope/core/utils/constants/enums.dart';
import 'package:civic_scope/features/settings/settings_screen.dart';
import 'package:civic_scope/shared/providers/auth_provider.dart';
import 'package:civic_scope/shared/providers/shared_preferences_provider.dart';
import 'package:civic_scope/shared/providers/theme_provider.dart';
import 'package:civic_scope/shared/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/test_preferences.dart';

void main() {
  testWidgets('guest sees login tile and theme selector', (tester) async {
  final prefs = await setUpTestPrefs();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      currentUserRoleProvider.overrideWithValue(UserRole.guest),
      signOutProvider.overrideWith((ref) => () {}),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: SettingsScreen()),
    ),
  );
  await tester.pumpAndSettle();

  expect(find.text('Settings'), findsOneWidget);
  expect(find.text('Theme'), findsOneWidget);
  expect(find.text('Log In / Sign Up'), findsOneWidget);
  expect(find.text('Log Out'), findsNothing);
});

  testWidgets('non-guest sees profile and logout actions', (tester) async {
    final prefs = await setUpTestPrefs();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        currentUserRoleProvider.overrideWithValue(UserRole.admin),
        signOutProvider.overrideWith((ref) => () {}),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Log In / Sign Up'), findsNothing);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Log Out'), findsOneWidget);
  });
}
