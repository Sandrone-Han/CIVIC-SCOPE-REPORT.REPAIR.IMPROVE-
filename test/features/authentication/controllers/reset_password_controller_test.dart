import 'package:civic_scope/features/authentication/controllers/reset_password_controller.dart';
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

  test('verifyCode stores email and marks code as verified on success', () async {
    final notifier = container.read(resetPasswordControllerProvider.notifier);

    fakeAuthRepository.verifyPasswordResetCodeHandler = (_) async => 'user@example.com';

    final result = await notifier.verifyCode('123456');
    final state = container.read(resetPasswordControllerProvider);

    expect(result, isTrue);
    expect(state.code, '123456');
    expect(state.email, 'user@example.com');
    expect(state.codeVerified, isTrue);
    expect(state.isVerifyingCode, isFalse);
    expect(fakeAuthRepository.verifyPasswordResetCodeCallCount, 1);
    expect(fakeAuthRepository.lastVerifiedCode, '123456');
  });

  test('verifyCode stores FirebaseAuthException message on failure', () async {
    final notifier = container.read(resetPasswordControllerProvider.notifier);

    fakeAuthRepository.verifyPasswordResetCodeHandler = (_) async {
      throw FirebaseAuthException(
        code: 'expired-action-code',
        message: 'Reset link has expired.',
      );
    };

    final result = await notifier.verifyCode('654321');
    final state = container.read(resetPasswordControllerProvider);

    expect(result, isFalse);
    expect(state.codeVerified, isFalse);
    expect(state.submitError, 'Reset link has expired.');
  });

  test('resetPassword confirms password reset and marks success', () async {
    final notifier = container.read(resetPasswordControllerProvider.notifier);

    fakeAuthRepository.verifyPasswordResetCodeHandler = (_) async => 'user@example.com';
    fakeAuthRepository.confirmPasswordResetHandler = (_, _) async {};

    await notifier.verifyCode('123456');
    notifier.updateNewPassword('secret123');
    notifier.updateConfirmPassword('secret123');

    final result = await notifier.resetPassword();
    final state = container.read(resetPasswordControllerProvider);

    expect(result, isTrue);
    expect(state.passwordReset, isTrue);
    expect(state.isSubmitting, isFalse);
    expect(state.submitError, isNull);
    expect(fakeAuthRepository.confirmPasswordResetCallCount, 1);
    expect(fakeAuthRepository.lastConfirmedCode, '123456');
    expect(fakeAuthRepository.lastConfirmedNewPassword, 'secret123');
  });

  test('resetPassword falls back to generic message for unexpected errors', () async {
    final notifier = container.read(resetPasswordControllerProvider.notifier);

    fakeAuthRepository.verifyPasswordResetCodeHandler = (_) async => 'user@example.com';
    fakeAuthRepository.confirmPasswordResetHandler = (_, _) async {
      throw Exception('service unavailable');
    };

    await notifier.verifyCode('123456');
    notifier.updateNewPassword('secret123');
    notifier.updateConfirmPassword('secret123');

    final result = await notifier.resetPassword();
    final state = container.read(resetPasswordControllerProvider);

    expect(result, isFalse);
    expect(state.passwordReset, isFalse);
    expect(state.submitError, 'Something went wrong, please try again.');
  });

  test('reset restores the initial state', () async {
    final notifier = container.read(resetPasswordControllerProvider.notifier);

    fakeAuthRepository.verifyPasswordResetCodeHandler = (_) async => 'user@example.com';
    await notifier.verifyCode('123456');
    notifier.updateNewPassword('secret123');
    notifier.updateConfirmPassword('secret123');
    notifier.reset();

    final state = container.read(resetPasswordControllerProvider);
    expect(state.code, '');
    expect(state.email, '');
    expect(state.newPassword, '');
    expect(state.confirmPassword, '');
    expect(state.codeVerified, isFalse);
    expect(state.passwordReset, isFalse);
    expect(state.submitError, isNull);
  });
}
