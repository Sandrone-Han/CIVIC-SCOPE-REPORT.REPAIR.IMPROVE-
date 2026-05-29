import 'package:civic_scope/features/authentication/controllers/log_in_controller.dart';
import 'package:civic_scope/features/authentication/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../../helpers/fake_auth_repository.dart';

class _LocalUser extends Mock implements User {
  _LocalUser({required String uid, String? email}) {
    when(this.uid).thenReturn(uid);
    when(this.email).thenReturn(email);
  }
}

class _LocalUserCredential extends Mock implements UserCredential {
  _LocalUserCredential({User? user}) {
    when(this.user).thenReturn(user);
  }
}

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

  test('starts with the expected initial state', () {
    final state = container.read(logInControllerProvider);

    expect(state.email, '');
    expect(state.password, '');
    expect(state.isSubmitting, isFalse);
    expect(state.submitError, isNull);
    expect(state.submitSuccess, isFalse);
  });

  test('updateEmail and updatePassword update the form state', () {
    final notifier = container.read(logInControllerProvider.notifier);

    notifier.updateEmail('user@example.com');
    notifier.updatePassword('secret123');

    final state = container.read(logInControllerProvider);
    expect(state.email, 'user@example.com');
    expect(state.password, 'secret123');
  });


  test('submit returns false and stores error when sign in fails', () async {
    final notifier = container.read(logInControllerProvider.notifier);

    notifier.updateEmail('user@example.com');
    notifier.updatePassword('wrong-password');
    fakeAuthRepository.signInHandler = (_, _) async {
      throw Exception('invalid credentials');
    };

    final result = await notifier.submit();
    final state = container.read(logInControllerProvider);

    expect(result, isFalse);
    expect(state.isSubmitting, isFalse);
    expect(state.submitSuccess, isFalse);
    expect(state.submitError, contains('invalid credentials'));
  });

  test('reset restores the initial state', () {
    final notifier = container.read(logInControllerProvider.notifier);

    notifier.updateEmail('user@example.com');
    notifier.updatePassword('secret123');
    notifier.reset();

    final state = container.read(logInControllerProvider);
    expect(state.email, '');
    expect(state.password, '');
    expect(state.isSubmitting, isFalse);
    expect(state.submitError, isNull);
    expect(state.submitSuccess, isFalse);
  });
}