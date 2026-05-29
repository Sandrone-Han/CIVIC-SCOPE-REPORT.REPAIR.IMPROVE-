import 'package:civic_scope/features/authentication/controllers/forgot_password_controller.dart';
import 'package:civic_scope/features/authentication/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository fakeAuthRepository;
  late ProviderContainer container;

  setUp(() {
    fakeAuthRepository = FakeAuthRepository();
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(fakeAuthRepository)],
    );
  });

  tearDown(() {
    fakeAuthRepository.dispose();
    container.dispose();
  });

  test('sendEmail marks emailSent on success', () async {
    final notifier = container.read(forgotPasswordControllerProvider.notifier);

    notifier.updateEmail('user@example.com');
    fakeAuthRepository.sendPasswordResetEmailHandler = (_) async {};

    final result = await notifier.sendEmail();
    final state = container.read(forgotPasswordControllerProvider);

    expect(result, isTrue);
    expect(state.email, 'user@example.com');
    expect(state.emailSent, isTrue);
    expect(state.isSubmitting, isFalse);
    expect(state.submitError, isNull);
    expect(fakeAuthRepository.sendPasswordResetEmailCallCount, 1);
    expect(fakeAuthRepository.lastResetEmail, 'user@example.com');
  });

  test('sendEmail stores FirebaseAuthException message on failure', () async {
    final notifier = container.read(forgotPasswordControllerProvider.notifier);

    notifier.updateEmail('missing@example.com');
    fakeAuthRepository.sendPasswordResetEmailHandler = (_) async {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No account exists for that email.',
      );
    };

    final result = await notifier.sendEmail();
    final state = container.read(forgotPasswordControllerProvider);

    expect(result, isFalse);
    expect(state.emailSent, isFalse);
    expect(state.isSubmitting, isFalse);
    expect(state.submitError, 'No account exists for that email.');
  });

  test('sendEmail falls back to generic message for unexpected errors', () async {
    final notifier = container.read(forgotPasswordControllerProvider.notifier);

    notifier.updateEmail('user@example.com');
    fakeAuthRepository.sendPasswordResetEmailHandler = (_) async {
      throw Exception('network down');
    };

    final result = await notifier.sendEmail();
    final state = container.read(forgotPasswordControllerProvider);

    expect(result, isFalse);
    expect(state.submitError, 'Something went wrong, try again.');
  });

  test('reset restores the initial state', () {
    final notifier = container.read(forgotPasswordControllerProvider.notifier);

    notifier.updateEmail('user@example.com');
    notifier.reset();

    final state = container.read(forgotPasswordControllerProvider);
    expect(state.email, '');
    expect(state.emailSent, isFalse);
    expect(state.isSubmitting, isFalse);
    expect(state.submitError, isNull);
  });
}
