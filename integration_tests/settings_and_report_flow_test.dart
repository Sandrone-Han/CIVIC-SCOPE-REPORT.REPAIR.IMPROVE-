import 'package:civic_scope/core/routing/app_routes.dart';
import 'package:civic_scope/core/utils/constants/enums.dart';
import 'package:civic_scope/features/reports/presentation/report_submitted_screen.dart';
import 'package:civic_scope/features/settings/settings_screen.dart';
import 'package:civic_scope/shared/providers/auth_provider.dart';
import 'package:civic_scope/shared/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';

import '../test/helpers/test_app.dart';
import '../test/helpers/test_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('guest settings changes theme and navigates to welcome', (
    tester,
  ) async {
    final prefs = await setUpTestPrefs();
    var signOutCalls = 0;

    final router = GoRouter(
      initialLocation: AppRoutes.settings,
      routes: [
        GoRoute(
          path: AppRoutes.settings,
          builder: (_, __) => const SettingsScreen(),
        ),
        GoRoute(
          path: AppRoutes.authWelcome,
          builder: (_, __) => const Scaffold(
            body: Center(child: Text('Welcome route')),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      buildRouterApp(
        router: router,
        prefs: prefs,
        overrides: [
          currentUserRoleProvider.overrideWithValue(UserRole.guest),
          signOutProvider.overrideWith((ref) => () {
                signOutCalls += 1;
              }),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('Log In / Sign Up'), findsOneWidget);

    await tester.tap(find.byType(DropdownButton<ThemeMode>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark').last);
    await tester.pumpAndSettle();

    expect(prefs.getString('theme_mode'), ThemeMode.dark.name);

    await tester.tap(find.text('Log In / Sign Up'));
    await tester.pumpAndSettle();

    expect(signOutCalls, 1);
    expect(find.text('Welcome route'), findsOneWidget);
  });

  testWidgets('theme selection persists after app rebuild', (tester) async {
    final prefs = await setUpTestPrefs();

    Future<void> pumpSettings() async {
      await tester.pumpWidget(
        buildProviderApp(
          prefs: prefs,
          overrides: [
            currentUserRoleProvider.overrideWithValue(UserRole.guest),
            signOutProvider.overrideWith((ref) => () {}),
          ],
          child: const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();
    }

    await pumpSettings();

    expect(find.text('Theme'), findsOneWidget);

    await tester.tap(find.byType(DropdownButton<ThemeMode>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark').last);
    await tester.pumpAndSettle();

    expect(prefs.getString('theme_mode'), ThemeMode.dark.name);

    await pumpSettings();

    expect(find.text('Settings'), findsOneWidget);
    expect(prefs.getString('theme_mode'), ThemeMode.dark.name);
    expect(find.text('Dark'), findsWidgets);
  });

  testWidgets('authenticated settings shows logout and triggers sign out', (
    tester,
  ) async {
    final prefs = await setUpTestPrefs();
    var signOutCalls = 0;

    await tester.pumpWidget(
      buildProviderApp(
        prefs: prefs,
        overrides: [
          currentUserRoleProvider.overrideWithValue(UserRole.company),
          signOutProvider.overrideWith((ref) => () {
                signOutCalls += 1;
              }),
        ],
        child: const SettingsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Log In / Sign Up'), findsNothing);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Bookmarked'), findsOneWidget);
    expect(find.text('Log Out'), findsOneWidget);

    await tester.tap(find.text('Log Out'));
    await tester.pumpAndSettle();

    expect(signOutCalls, 1);
  });

  testWidgets('report submitted screen persists state and returns home', (
    tester,
  ) async {
    final prefs = await setUpTestPrefs();

    final router = GoRouter(
      initialLocation: '/submitted',
      routes: [
        GoRoute(
          path: '/submitted',
          builder: (_, __) => const ReportSubmittedScreen(
            reportCategory: 'pothole',
            reportStatus: 'reported',
          ),
        ),
        GoRoute(
          path: AppRoutes.homeMap,
          builder: (_, __) => const Scaffold(
            body: Center(child: Text('Home map route')),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      buildRouterApp(
        router: router,
        prefs: prefs,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Report Submitted'), findsOneWidget);
    expect(find.text('Thank You!'), findsOneWidget);
    expect(find.text('Category: pothole'), findsOneWidget);
    expect(find.text('Status: reported'), findsOneWidget);
    expect(prefs.getString('last_screen'), 'report_submitted');

    await tester.tap(find.widgetWithText(FilledButton, 'Go to Home'));
    await tester.pumpAndSettle();

    expect(find.text('Home map route'), findsOneWidget);
  });
}