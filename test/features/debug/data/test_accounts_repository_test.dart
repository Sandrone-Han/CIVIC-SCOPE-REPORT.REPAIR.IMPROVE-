import 'package:civic_scope/core/utils/constants/enums.dart';
import 'package:civic_scope/features/debug/data/test_accounts_repository.dart';
//import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
//import 'package:mockito/mockito.dart';

import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/fake_user_repository.dart';



void main() {
  group('TestAccountsRepository', () {
    late FakeAuthRepository authRepository;
    late FakeUserRepository userRepository;
    late TestAccountsRepository repository;

    setUp(() {
      authRepository = FakeAuthRepository();
      userRepository = FakeUserRepository();
      repository = TestAccountsRepository(
        authRepository: authRepository,
        userRepository: userRepository,
      );
    });

    tearDown(() {
      authRepository.dispose();
      userRepository.dispose();
    });

    test('returns null credentials for guest and configured credentials for citizen', () {
      expect(repository.getTestCredentials(UserRole.guest), isNull);

      final citizen = repository.getTestCredentials(UserRole.citizen);
      expect(citizen, isNotNull);
      expect(citizen!['email'], 'test.citizen@civic.test');
      expect(citizen['displayName'], 'Test Citizen');
    });

    test('testAccountExists returns false when authentication fails', () async {
      authRepository.signInHandler = (_, __) async {
        throw Exception('bad-credentials');
      };

      final exists = await repository.testAccountExists(UserRole.council);

      expect(exists, isFalse);
      expect(authRepository.signOutCallCount, 0);
    });
  });
}