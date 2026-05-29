import 'package:civic_scope/core/routing/app_routes.dart';
import 'package:civic_scope/features/authentication/presentation/reset_password_screen.dart';
import 'package:civic_scope/features/authentication/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_preferences.dart';

void main() {
  late FakeAuthRepository fakeAuthRepository;

  Future<void> pumpResetPasswordScreen(WidgetTester tester, {required String code}) async {
    final prefs = await setUpTestPrefs();
    final router = GoRouter(
      initialLocation: '/reset',
      routes: [
        GoRoute(
          path: AppRoutes.homeMap,
          builder: (_, _) => const Scaffold(body: Text('Home map route')),
        ),
        GoRoute(
          path: '/reset',
          builder: (_, _) => ResetPasswordScreen(code: code),
        ),
      ],
    );

    await tester.pumpWidget(
      buildRouterApp(
        prefs: prefs,
        router: router,
        overrides: [authRepositoryProvider.overrideWithValue(fakeAuthRepository)],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  setUp(() {
    fakeAuthRepository = FakeAuthRepository();
  });

  tearDown(() {
    fakeAuthRepository.dispose();
  });

  testWidgets('verifies the reset code and shows the password form', (tester) async {
    fakeAuthRepository.verifyPasswordResetCodeHandler = (_) async => 'user@example.com';

    await pumpResetPasswordScreen(tester, code: 'ABC123');

    expect(find.text('Create new password'), findsOneWidget);
    expect(find.textContaining('user@example.com'), findsOneWidget);
    expect(fakeAuthRepository.lastVerifiedCode, 'ABC123');
  });

  testWidgets('shows invalid reset link message when verification fails', (tester) async {
    fakeAuthRepository.verifyPasswordResetCodeHandler = (_) async {
      throw FirebaseAuthException(
        code: 'invalid-action-code',
        message: 'The password reset link is invalid or has expired.',
      );
    };

    await pumpResetPasswordScreen(tester, code: 'BADCODE');

    expect(find.text('Invalid Reset Link'), findsOneWidget);
    expect(find.text('This password reset link is invalid or has expired.'), findsOneWidget);
    expect(fakeAuthRepository.lastVerifiedCode, 'BADCODE');
  });

  testWidgets('successful reset submits the new password and navigates home', (tester) async {
    fakeAuthRepository.verifyPasswordResetCodeHandler = (_) async => 'user@example.com';
    fakeAuthRepository.confirmPasswordResetHandler = (_, _) async {};

    await pumpResetPasswordScreen(tester, code: 'GOOD123');

    final passwordFields = find.byType(TextFormField);
    expect(passwordFields, findsNWidgets(2));

    await tester.enterText(passwordFields.at(0), 'secret123');
    await tester.enterText(passwordFields.at(1), 'secret123');
    await tester.tap(find.widgetWithText(FilledButton, 'Reset Password'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(fakeAuthRepository.confirmPasswordResetCallCount, 1);
    expect(fakeAuthRepository.lastConfirmedCode, 'GOOD123');
    expect(fakeAuthRepository.lastConfirmedNewPassword, 'secret123');
    expect(find.text('Password reset successful! You can now log in.'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Home map route'), findsOneWidget);
  });
}
