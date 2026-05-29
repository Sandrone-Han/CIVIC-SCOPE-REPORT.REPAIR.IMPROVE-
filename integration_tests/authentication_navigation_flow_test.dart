import 'package:civic_scope/core/routing/app_routes.dart';
import 'package:civic_scope/features/authentication/presentation/forgot_password_screen.dart';
import 'package:civic_scope/features/authentication/presentation/log_in_screen.dart';
import 'package:civic_scope/features/authentication/presentation/reset_password_screen.dart';
import 'package:civic_scope/features/authentication/presentation/sign_up_screen.dart';
import 'package:civic_scope/features/authentication/repositories/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';

import '../test/helpers/fake_auth_repository.dart';
import '../test/helpers/test_app.dart';
import '../test/helpers/test_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late FakeAuthRepository fakeAuthRepository;

  setUp(() {
    fakeAuthRepository = FakeAuthRepository();
  });

  tearDown(() {
    fakeAuthRepository.dispose();
  });

  

  testWidgets('log in page -> forgot password page -> back to log in', (
    tester,
  ) async {
    final prefs = await setUpTestPrefs();

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const LoginPage(),
        ),
        GoRoute(
          path: AppRoutes.authForgotPassword,
          builder: (_, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return ForgotPasswordScreen(
              initialEmail: extra?['email'] as String? ?? '',
            );
          },
        ),
      ],
    );

    await tester.pumpWidget(
      buildRouterApp(
        router: router,
        prefs: prefs,
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeAuthRepository),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'user@example.com',
    );
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();

    expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    expect(find.text('Forgot Password'), findsOneWidget);
    expect(find.text('user@example.com'), findsOneWidget);

    await tester.tap(find.text('Back to Log In'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('forgot password screen submits reset email successfully', (
    tester,
  ) async {
    final prefs = await setUpTestPrefs();
    fakeAuthRepository.sendPasswordResetEmailHandler = (_) async {};

    await tester.pumpWidget(
      buildProviderApp(
        prefs: prefs,
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeAuthRepository),
        ],
        child: const ForgotPasswordScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).first,
      'reset@example.com',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Send Reset Link'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(fakeAuthRepository.sendPasswordResetEmailCallCount, 1);
    expect(fakeAuthRepository.lastResetEmail, 'reset@example.com');
    expect(
      find.text('Click the link in the email to reset your password.'),
      findsOneWidget,
    );
  });

  testWidgets('log in page -> sign up page with prefilled email and password', (
    tester,
  ) async {
    final prefs = await setUpTestPrefs();

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const LoginPage(),
        ),
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
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeAuthRepository),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'jane@example.com',
    );
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'secret123',
    );

    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();

    expect(find.byType(SignUpScreen), findsOneWidget);
    expect(find.text('Sign Up'), findsOneWidget);
    expect(find.text('jane@example.com'), findsOneWidget);
    expect(find.text('secret123'), findsOneWidget);

    final logInFinder = find.text('Log in');
    await tester.ensureVisible(logInFinder);
    await tester.tap(logInFinder);
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('reset password success flow verifies code and returns home', (
    tester,
  ) async {
    final prefs = await setUpTestPrefs();

    fakeAuthRepository.verifyPasswordResetCodeHandler =
        (_) async => 'user@example.com';
    fakeAuthRepository.confirmPasswordResetHandler = (_, __) async {};

    final router = GoRouter(
      initialLocation: '/reset',
      routes: [
        GoRoute(
          path: AppRoutes.homeMap,
          builder: (_, __) => const Scaffold(
            body: Center(child: Text('Home map route')),
          ),
        ),
        GoRoute(
          path: '/reset',
          builder: (_, __) => const ResetPasswordScreen(code: 'RESET123'),
        ),
      ],
    );

    await tester.pumpWidget(
      buildRouterApp(
        prefs: prefs,
        router: router,
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeAuthRepository),
        ],
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(ResetPasswordScreen), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Reset Password'), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'secret123',
    );
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'secret123',
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Reset Password'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(fakeAuthRepository.verifyPasswordResetCodeCallCount, 1);
    expect(fakeAuthRepository.confirmPasswordResetCallCount, 1);
    expect(
      find.text('Password reset successful! You can now log in.'),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('Home map route'), findsOneWidget);
  });
}
