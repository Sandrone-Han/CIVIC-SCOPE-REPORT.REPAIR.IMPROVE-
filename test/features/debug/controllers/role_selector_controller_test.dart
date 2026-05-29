import 'package:civic_scope/core/utils/constants/enums.dart';
import 'package:civic_scope/features/debug/controllers/role_selector_controller.dart';
import 'package:civic_scope/features/debug/data/test_accounts_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/fake_user_repository.dart';

class FakeTestAccountsRepository extends TestAccountsRepository {
  FakeTestAccountsRepository()
      : super(
          authRepository: FakeAuthRepository(),
          userRepository: FakeUserRepository(),
        );

  Future<void> Function()? seedHandler;
  Future<void> Function(UserRole role)? signInHandler;

  int seedCallCount = 0;
  int signInCallCount = 0;
  UserRole? lastSignInRole;

  @override
  Future<void> seedTestAccounts() async {
    seedCallCount += 1;
    await (seedHandler?.call() ?? Future<void>.value());
  }

  @override
  Future<void> signInAsTestUser(UserRole role) async {
    signInCallCount += 1;
    lastSignInRole = role;
    await (signInHandler?.call(role) ?? Future<void>.value());
  }
}

void main() {
  group('RoleSelectorController', () {
    late FakeTestAccountsRepository repository;
    late ProviderContainer container;

    setUp(() {
      repository = FakeTestAccountsRepository();
      container = ProviderContainer(
        overrides: [
          testAccountsRepositoryProvider.overrideWithValue(repository),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('seedTestAccountsIfNeeded sets and clears loading state on success', () async {
      final controller = container.read(roleSelectorControllerProvider.notifier);

      expect(container.read(roleSelectorControllerProvider).isSeeding, isFalse);

      final future = controller.seedTestAccountsIfNeeded();
      expect(container.read(roleSelectorControllerProvider).isSeeding, isTrue);

      await future;

      final state = container.read(roleSelectorControllerProvider);
      expect(repository.seedCallCount, 1);
      expect(state.isSeeding, isFalse);
      expect(state.error, isNull);
    });

    test('seedTestAccountsIfNeeded stores error on failure', () async {
      repository.seedHandler = () async {
        throw Exception('seed failed');
      };

      await container
          .read(roleSelectorControllerProvider.notifier)
          .seedTestAccountsIfNeeded();

      final state = container.read(roleSelectorControllerProvider);
      expect(state.isSeeding, isFalse);
      expect(state.error, contains('Failed to seed test accounts'));
    });

    test('signInAs sets success message on success', () async {
      final success = await container
          .read(roleSelectorControllerProvider.notifier)
          .signInAs(UserRole.citizen);

      final state = container.read(roleSelectorControllerProvider);
      expect(success, isTrue);
      expect(repository.signInCallCount, 1);
      expect(repository.lastSignInRole, UserRole.citizen);
      expect(state.isSigningIn, isFalse);
      expect(state.success, contains('Signed in as'));
      expect(state.success, contains('test.citizen@civic.test'));
      expect(state.success, contains('Test Citizen'));
      expect(state.error, isNull);
    });

    test('signInAs stores error on failure and returns false', () async {
      repository.signInHandler = (_) async {
        throw Exception('denied');
      };

      final success = await container
          .read(roleSelectorControllerProvider.notifier)
          .signInAs(UserRole.admin);

      final state = container.read(roleSelectorControllerProvider);
      expect(success, isFalse);
      expect(state.isSigningIn, isFalse);
      expect(state.error, contains('Failed to sign in as admin'));
    });

    test('clearError removes current error message', () async {
      repository.signInHandler = (_) async {
        throw Exception('failure');
      };

      await container
          .read(roleSelectorControllerProvider.notifier)
          .signInAs(UserRole.worker);
      expect(container.read(roleSelectorControllerProvider).error, isNotNull);

      container.read(roleSelectorControllerProvider.notifier).clearError();

      expect(container.read(roleSelectorControllerProvider).error, isNull);
    });
  });
}
