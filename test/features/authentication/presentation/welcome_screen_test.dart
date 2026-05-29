import 'package:civic_scope/core/routing/app_routes.dart';
import 'package:civic_scope/features/authentication/presentation/welcome_screen.dart';
import 'package:civic_scope/shared/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../helpers/test_app.dart';
import '../../../helpers/test_preferences.dart';

GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: AppRoutes.authWelcome,
    routes: [
      GoRoute(
        path: AppRoutes.authWelcome,
        builder: (_, _) => const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.homeMap,
        builder: (_, _) => const Scaffold(body: Text('Home Map')),
      ),
      GoRoute(
        path: AppRoutes.authLogIn,
        builder: (_, _) => const Scaffold(body: Text('Login Route')),
      ),
      GoRoute(
        path: AppRoutes.authSignUp,
        builder: (_, _) => const Scaffold(body: Text('Sign Up Route')),
      ),
      GoRoute(
        path: AppRoutes.debugRoleSelector,
        builder: (_, _) => const Scaffold(body: Text('Role Selector Route')),
      ),
    ],
  );
}

void main() {
  testWidgets('welcome screen renders primary entry actions', (tester) async {
    final prefs = await setUpTestPrefs();

    await tester.pumpWidget(
      buildRouterApp(
        router: _buildRouter(),
        prefs: prefs,
        overrides: [
          signOutProvider.overrideWithValue(() {}),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Continue as Guest'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Sign Up'), findsOneWidget);
    expect(find.text('Test Role Selector'), findsNothing);
  });

  testWidgets('continue as guest navigates to home map', (tester) async {
    final prefs = await setUpTestPrefs();

    await tester.pumpWidget(
      buildRouterApp(
        router: _buildRouter(),
        prefs: prefs,
        overrides: [
          signOutProvider.overrideWithValue(() {}),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue as Guest'));
    await tester.pumpAndSettle();

    expect(find.text('Home Map'), findsOneWidget);
  });

  testWidgets('sign in and sign up buttons navigate to their routes', (tester) async {
    final prefs = await setUpTestPrefs();
    final router = _buildRouter();

    await tester.pumpWidget(
      buildRouterApp(
        router: router,
        prefs: prefs,
        overrides: [
          signOutProvider.overrideWithValue(() {}),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();
    expect(find.text('Login Route'), findsOneWidget);

    router.go(AppRoutes.authWelcome);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();
    expect(find.text('Sign Up Route'), findsOneWidget);
  });

  testWidgets('enabling debug mode reveals role selector button', (tester) async {
    final prefs = await setUpTestPrefs();

    await tester.pumpWidget(
      buildRouterApp(
        router: _buildRouter(),
        prefs: prefs,
        overrides: [
          signOutProvider.overrideWithValue(() {}),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Debug Mode'));
    await tester.pumpAndSettle();

    expect(find.text('Enable Debug Mode?'), findsOneWidget);
    await tester.tap(find.text('Enable'));
    await tester.pumpAndSettle();

    expect(prefs.getBool('debug_mode'), isTrue);
    expect(find.text('Test Role Selector'), findsOneWidget);
  });

  
}
