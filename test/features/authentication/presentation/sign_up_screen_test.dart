import 'package:civic_scope/features/authentication/presentation/sign_up_screen.dart';
import 'package:civic_scope/features/authentication/repositories/auth_repository.dart';
import 'package:civic_scope/features/authentication/repositories/user_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/fake_user_repository.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_preferences.dart';

void main() {
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

  testWidgets('renders all registration fields', (tester) async {
    final prefs = await setUpTestPrefs();

    await tester.pumpWidget(
      buildProviderApp(
        prefs: prefs,
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeAuthRepository),
          userRepositoryProvider.overrideWithValue(fakeUserRepository),
        ],
        child: const SignUpScreen(),
      ),
    );

    expect(find.text('Hello, Welcome'), findsOneWidget);
    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Confirm Password'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);
  });

  testWidgets('shows validation messages when submitting empty form', (tester) async {
    final prefs = await setUpTestPrefs();

    await tester.pumpWidget(
      buildProviderApp(
        prefs: prefs,
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeAuthRepository),
          userRepositoryProvider.overrideWithValue(fakeUserRepository),
        ],
        child: const SignUpScreen(),
      ),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Create Account'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter your name'), findsOneWidget);
    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
    expect(find.text('Please confirm your password'), findsOneWidget);
  });

  
}
