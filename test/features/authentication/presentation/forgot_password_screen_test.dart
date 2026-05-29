import 'package:civic_scope/features/authentication/presentation/forgot_password_screen.dart';
import 'package:civic_scope/features/authentication/repositories/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

  testWidgets('shows the initial email when provided', (tester) async {
    final prefs = await setUpTestPrefs();

    await tester.pumpWidget(
      buildProviderApp(
        prefs: prefs,
        overrides: [authRepositoryProvider.overrideWithValue(fakeAuthRepository)],
        child: const ForgotPasswordScreen(initialEmail: 'prefill@example.com'),
      ),
    );

    expect(find.text('prefill@example.com'), findsOneWidget);
  });

  testWidgets('shows validation message when submitting empty email', (tester) async {
    final prefs = await setUpTestPrefs();

    await tester.pumpWidget(
      buildProviderApp(
        prefs: prefs,
        overrides: [authRepositoryProvider.overrideWithValue(fakeAuthRepository)],
        child: const ForgotPasswordScreen(),
      ),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Send Reset Link'));
    await tester.pumpAndSettle();

    expect(find.text('Email is required'), findsOneWidget);
  });

  testWidgets('successful submit shows snackbar and info message', (tester) async {
    final prefs = await setUpTestPrefs();
    fakeAuthRepository.sendPasswordResetEmailHandler = (_) async {};

    await tester.pumpWidget(
      buildProviderApp(
        prefs: prefs,
        overrides: [authRepositoryProvider.overrideWithValue(fakeAuthRepository)],
        child: const ForgotPasswordScreen(),
      ),
    );

    await tester.enterText(find.byType(TextFormField), 'user@example.com');
    await tester.tap(find.widgetWithText(FilledButton, 'Send Reset Link'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(fakeAuthRepository.sendPasswordResetEmailCallCount, 1);
    expect(fakeAuthRepository.lastResetEmail, 'user@example.com');
    expect(find.text('Reset link sent! Check your email.'), findsOneWidget);
    expect(find.text('Click the link in the email to reset your password.'), findsOneWidget);
  });
}
