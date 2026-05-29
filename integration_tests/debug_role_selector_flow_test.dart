import 'package:civic_scope/core/routing/app_routes.dart';
import 'package:civic_scope/features/authentication/presentation/welcome_screen.dart';
import 'package:civic_scope/features/authentication/repositories/auth_repository.dart';
import 'package:civic_scope/features/authentication/repositories/user_repository.dart';
import 'package:civic_scope/features/debug/presentation/role_selector_screen.dart';
import 'package:civic_scope/shared/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';

import '../test/helpers/fake_auth_repository.dart';
import '../test/helpers/fake_user_repository.dart';
import '../test/helpers/test_app.dart';
import '../test/helpers/test_preferences.dart';

const Duration kStepPause = Duration(seconds: 2);
const Duration kEndPause = Duration(seconds: 3);

Future<void> watchStep(
  WidgetTester tester, {
  Duration duration = kStepPause,
}) async {
  await tester.pump();
  await Future.delayed(duration);
  await tester.pump();
}

Future<void> settleAndWatch(
  WidgetTester tester, {
  Duration duration = kStepPause,
}) async {
  await tester.pumpAndSettle();
  await Future.delayed(duration);
  await tester.pump();
}

Future<void> shortAsyncAndWatch(
  WidgetTester tester, {
  Duration internalPump = const Duration(milliseconds: 300),
  Duration watch = kStepPause,
}) async {
  await tester.pump();
  await tester.pump(internalPump);
  await Future.delayed(watch);
  await tester.pump();
}

Future<void> finishWatching(
  WidgetTester tester, {
  Duration duration = kEndPause,
}) async {
  await tester.pump();
  await Future.delayed(duration);
  await tester.pump();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late FakeAuthRepository fakeAuthRepository;
  late FakeUserRepository fakeUserRepository;

  setUp(() {
    fakeAuthRepository = FakeAuthRepository();
    fakeUserRepository = FakeUserRepository();
  });

  tearDown(() {
    fakeAuthRepository.dispose();
    fakeUserRepository.dispose();
  });

  testWidgets('welcome screen enables debug mode and opens role selector', (
    tester,
  ) async {
    final prefs = await setUpTestPrefs();
    var signOutCalls = 0;

    final router = GoRouter(
      initialLocation: AppRoutes.authWelcome,
      routes: [
        GoRoute(
          path: AppRoutes.authWelcome,
          builder: (_, __) => const WelcomeScreen(),
        ),
        GoRoute(
          path: AppRoutes.debugRoleSelector,
          builder: (_, __) => const RoleSelectorScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      buildRouterApp(
        router: router,
        prefs: prefs,
        overrides: [
          signOutProvider.overrideWith((ref) => () {
                signOutCalls += 1;
              }),
          authRepositoryProvider.overrideWithValue(fakeAuthRepository),
          userRepositoryProvider.overrideWithValue(fakeUserRepository),
        ],
      ),
    );
    await settleAndWatch(tester);

    expect(find.text('Test Role Selector'), findsNothing);

    await tester.tap(find.byTooltip('Debug Mode'));
    await settleAndWatch(tester);
    expect(find.text('Enable Debug Mode?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Enable'));
    await settleAndWatch(tester);

    expect(signOutCalls, 1);
    expect(find.text('Test Role Selector'), findsOneWidget);

    await tester.tap(find.text('Test Role Selector'));
    await settleAndWatch(tester);

    expect(find.byType(RoleSelectorScreen), findsOneWidget);
    expect(find.text('DEBUG MODE ACTIVE'), findsOneWidget);
    expect(find.text('Launch as Admin'), findsOneWidget);
    await finishWatching(tester);
  });

  testWidgets('role selector signs in as admin and redirects to auth loading', (
    tester,
  ) async {
    final prefs = await setUpTestPrefs({'debug_mode': true});

    fakeAuthRepository.signInHandler = (email, password) async {
      return DummyUserCredential(
        user: DummyUser(
          uid: 'admin-user',
          email: email,
          displayName: 'Test Admin',
        ),
      );
    };

    final router = GoRouter(
      initialLocation: AppRoutes.debugRoleSelector,
      routes: [
        GoRoute(
          path: AppRoutes.debugRoleSelector,
          builder: (_, __) => const RoleSelectorScreen(),
        ),
        GoRoute(
          path: AppRoutes.authLoading,
          builder: (_, __) => const Scaffold(
            body: Center(child: Text('Auth loading route')),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      buildRouterApp(
        router: router,
        prefs: prefs,
        overrides: [
          signOutProvider.overrideWith((ref) => () {}),
          authRepositoryProvider.overrideWithValue(fakeAuthRepository),
          userRepositoryProvider.overrideWithValue(fakeUserRepository),
        ],
      ),
    );
    await settleAndWatch(tester);

    await tester.tap(find.text('Launch as Admin'));
    await shortAsyncAndWatch(tester);

    expect(fakeAuthRepository.signInCallCount, 1);
    expect(fakeAuthRepository.lastSignInEmail, 'test.admin@civic.test');
    expect(fakeAuthRepository.lastSignInPassword, 'test123456');
    expect(find.text('Auth loading route'), findsOneWidget);
    await finishWatching(tester);
  });
}