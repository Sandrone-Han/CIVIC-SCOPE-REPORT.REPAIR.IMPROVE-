import 'package:civic_scope/core/routing/app_routes.dart';
import 'package:civic_scope/features/authentication/presentation/forgot_password_screen.dart';
import 'package:civic_scope/features/authentication/presentation/log_in_screen.dart';
import 'package:civic_scope/features/authentication/presentation/sign_up_screen.dart';
import 'package:civic_scope/features/authentication/repositories/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_preferences.dart';

void main() {
  late FakeAuthRepository fakeAuthRepository;

  setUp(() {
    fakeAuthRepository = FakeAuthRepository();
  });

  tearDown(() {
    fakeAuthRepository.dispose();
  });

  testWidgets('renders core form fields and submit button', (tester) async {
    final prefs = await setUpTestPrefs();

    await tester.pumpWidget(
      buildProviderApp(
        prefs: prefs,
        overrides: [authRepositoryProvider.overrideWithValue(fakeAuthRepository)],
        child: const LoginPage(),
      ),
    );

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
    expect(find.text('Log In'), findsWidgets);
  });

  testWidgets('shows validation errors for empty fields', (tester) async {
    final prefs = await setUpTestPrefs();

    await tester.pumpWidget(
      buildProviderApp(
        prefs: prefs,
        overrides: [authRepositoryProvider.overrideWithValue(fakeAuthRepository)],
        child: const LoginPage(),
      ),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Log In'));
    await tester.pumpAndSettle();

    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
  });


  testWidgets('forgot password navigation passes the current email', (tester) async {
    final prefs = await setUpTestPrefs();
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, _) => const LoginPage()),
        GoRoute(
          path: AppRoutes.authForgotPassword,
          builder: (_, state) => ForgotPasswordScreen(
            initialEmail: (state.extra as Map<String, dynamic>?)?['email'] as String? ?? '',
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      buildRouterApp(
        router: router,
        prefs: prefs,
        overrides: [authRepositoryProvider.overrideWithValue(fakeAuthRepository)],
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'prefill@example.com');
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();

    expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    expect(find.text('Reset your password'), findsOneWidget);
    expect(find.text('prefill@example.com'), findsOneWidget);
  });

  testWidgets('sign up navigation passes the current credentials', (tester) async {
    final prefs = await setUpTestPrefs();
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, _) => const LoginPage()),
        GoRoute(
          path: AppRoutes.authSignUp,
          builder: (_, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return SignUpScreen(
              initialEmail: extra?['email'] as String? ?? '',
              initialPassword: extra?['password'] as String? ?? '',
            );
          },
        ),
      ],
    );

    await tester.pumpWidget(
      buildRouterApp(
        router: router,
        prefs: prefs,
        overrides: [authRepositoryProvider.overrideWithValue(fakeAuthRepository)],
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'prefill@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'secret123');
    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();

    expect(find.byType(SignUpScreen), findsOneWidget);
    expect(find.text('prefill@example.com'), findsOneWidget);
  });
}
