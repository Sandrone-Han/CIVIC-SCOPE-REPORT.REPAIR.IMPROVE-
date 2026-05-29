import 'package:civic_scope/core/routing/app_router.dart';
import 'package:civic_scope/core/routing/app_routes.dart';
import 'package:civic_scope/core/utils/constants/enums.dart';
import 'package:civic_scope/features/authentication/presentation/log_in_screen.dart';
import 'package:civic_scope/features/authentication/presentation/sign_up_screen.dart';
import 'package:civic_scope/features/roles/guest/presentation/guest_scaffold.dart';
import 'package:civic_scope/features/settings/settings_screen.dart';
import 'package:civic_scope/shared/providers/auth_provider.dart';
import 'package:civic_scope/shared/providers/shared_preferences_provider.dart';
import 'package:civic_scope/shared/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_preferences.dart';

GoRouter _buildShellRouter() {
  return GoRouter(
    initialLocation: AppRoutes.settings,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            GuestScaffold(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.homeMap,
                builder: (_, _) => const Scaffold(body: Text('Map screen')),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.searchReports,
                builder: (_, _) => const Scaffold(body: Text('Search screen')),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                builder: (_, _) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

void main() {
  test('app router defaults to the auth loading route configuration', () async {
    final prefs = await setUpTestPrefs();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        authStateProvider.overrideWithValue(AppAuthState.loading),
        currentUserRoleProvider.overrideWithValue(UserRole.guest),
      ],
    );
    addTearDown(container.dispose);

    final appRouter = container.read(appRouterProvider);
    expect(appRouter.routeInformationProvider.value.uri.path, AppRoutes.authLoading);
  });

  testWidgets('unauthenticated guest router resolves the login route', (tester) async {
    final prefs = await setUpTestPrefs();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        authStateProvider.overrideWithValue(AppAuthState.unauthenticated),
        currentUserRoleProvider.overrideWithValue(UserRole.guest),
      ],
    );
    addTearDown(container.dispose);

    final appRouter = container.read(appRouterProvider);
    appRouter.go(AppRoutes.authLogIn);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: appRouter),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
  });


  testWidgets('settings shell route shows guest bottom navigation', (tester) async {
    final prefs = await setUpTestPrefs();
    final shellRouter = _buildShellRouter();

    await tester.pumpWidget(buildRouterApp(router: shellRouter, prefs: prefs));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.text('Map'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Settings'), findsWidgets);
  });
}
