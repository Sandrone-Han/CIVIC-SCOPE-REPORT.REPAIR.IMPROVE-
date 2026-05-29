import 'package:civic_scope/core/utils/constants/enums.dart';
import 'package:civic_scope/features/authentication/controllers/sign_up_controller.dart';
import 'package:civic_scope/features/authentication/repositories/auth_repository.dart';
import 'package:civic_scope/features/authentication/repositories/user_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/fake_user_repository.dart';

class _LocalUser extends Mock implements User {
  _LocalUser({required String uid, String? email, String? displayName}) {
    when(this.uid).thenReturn(uid);
    when(this.email).thenReturn(email);
    when(this.displayName).thenReturn(displayName);
  }
}

class _LocalUserCredential extends Mock implements UserCredential {
  _LocalUserCredential({required User user}) {
    when(this.user).thenReturn(user);
  }
}

void main() {
  late FakeAuthRepository fakeAuthRepository;
  late FakeUserRepository fakeUserRepository;
  late ProviderContainer container;

  setUp(() {
    fakeAuthRepository = FakeAuthRepository();
    fakeUserRepository = FakeUserRepository();
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeAuthRepository),
        userRepositoryProvider.overrideWithValue(fakeUserRepository),
      ],
    );
  });

  tearDown(() {
    fakeAuthRepository.dispose();
    fakeUserRepository.dispose();
    container.dispose();
  });

  test('starts with the expected initial state', () {
    final state = container.read(signUpControllerProvider);

    expect(state.name, '');
    expect(state.email, '');
    expect(state.password, '');
    expect(state.confirmPassword, '');
    expect(state.isSubmitting, isFalse);
    expect(state.submitError, isNull);
    expect(state.submitSuccess, isFalse);
  });

  test('field updaters update the signup state', () {
    final notifier = container.read(signUpControllerProvider.notifier);

    notifier.updateName('Jane Smith');
    notifier.updateEmail('jane@example.com');
    notifier.updatePassword('secret123');
    notifier.updateConfirmPassword('secret123');

    final state = container.read(signUpControllerProvider);
    expect(state.name, 'Jane Smith');
    expect(state.email, 'jane@example.com');
    expect(state.password, 'secret123');
    expect(state.confirmPassword, 'secret123');
  });




  test('signUp stores FirebaseAuthException message on failure', () async {
    final notifier = container.read(signUpControllerProvider.notifier);

    notifier.updateName('Jane Smith');
    notifier.updateEmail('jane@example.com');
    notifier.updatePassword('secret123');
    notifier.updateConfirmPassword('secret123');

    fakeAuthRepository.createUserHandler = (_, _) async {
      throw FirebaseAuthException(
        code: 'email-already-in-use',
        message: 'This email is already in use.',
      );
    };

    final result = await notifier.signUp();
    final state = container.read(signUpControllerProvider);

    expect(result, isFalse);
    expect(state.submitSuccess, isFalse);
    expect(state.submitError, 'This email is already in use.');
    expect(fakeUserRepository.createUserCallCount, 0);
  });

  test('reset restores the initial state', () {
    final notifier = container.read(signUpControllerProvider.notifier);

    notifier.updateName('Jane Smith');
    notifier.updateEmail('jane@example.com');
    notifier.updatePassword('secret123');
    notifier.updateConfirmPassword('secret123');
    notifier.reset();

    final state = container.read(signUpControllerProvider);
    expect(state.name, '');
    expect(state.email, '');
    expect(state.password, '');
    expect(state.confirmPassword, '');
    expect(state.isSubmitting, isFalse);
    expect(state.submitError, isNull);
    expect(state.submitSuccess, isFalse);
  });
}