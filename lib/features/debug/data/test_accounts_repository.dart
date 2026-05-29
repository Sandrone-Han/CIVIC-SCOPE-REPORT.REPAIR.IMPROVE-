import 'package:civic_scope/core/utils/constants/enums.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/authentication/repositories/auth_repository.dart';
import '../../../features/authentication/repositories/user_repository.dart';
import '../../../features/authentication/domain/user_model.dart';

// Repository provider for dependency injection
final testAccountsRepositoryProvider = Provider<TestAccountsRepository>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  final userRepo = ref.watch(userRepositoryProvider);
  return TestAccountsRepository(
    authRepository: authRepo,
    userRepository: userRepo,
  );
});

/// Repository for managing test accounts used in debug mode
///
/// Provides pre-configured test users for each role to enable
/// quick testing without manual account creation
class TestAccountsRepository {
  final AuthRepository authRepository;
  final UserRepository userRepository;

  TestAccountsRepository({
    required this.authRepository,
    required this.userRepository,
  });

  /// Common password for all test accounts
  static const String testPassword = 'test123456';

  /// Test account credentials mapped by role
  static const Map<UserRole, Map<String, String>> _testAccounts = {
    UserRole.citizen: {
      'email': 'test.citizen@civic.test',
      'displayName': 'Test Citizen',
    },
    UserRole.worker: {
      'email': 'test.worker@civic.test',
      'displayName': 'Test Worker',
    },
    UserRole.company: {
      'email': 'test.company@civic.test',
      'displayName': 'Test Company',
    },
    UserRole.council: {
      'email': 'test.council@civic.test',
      'displayName': 'Test Council',
    },
    UserRole.admin: {
      'email': 'test.admin@civic.test',
      'displayName': 'Test Admin',
    },
  };

  /// Get test account credentials for a specific role
  Map<String, String>? getTestCredentials(UserRole role) {
    if (role == UserRole.guest) {
      return null; // Guest doesn't have test account
    }
    return _testAccounts[role];
  }

  /// Sign in as a test user for the given role
  ///
  /// If the test account doesn't exist, it will be created automatically
  /// Throws [Exception] if role is guest or if sign-in fails
  Future<void> signInAsTestUser(UserRole role) async {

    final credentials = _testAccounts[role];
    if (credentials == null) {
      throw Exception('No test account configured for role: ${role.name}');
    }

    final email = credentials['email']!;
    final displayName = credentials['displayName']!;

    try {
      // Try to sign in
      await authRepository.signInWithEmailAndPassword(
        email: email,
        password: testPassword,
      );
    } catch (e) {
      // If sign-in fails, create the account
      try {
        final userCredential = await authRepository.createUserWithEmailAndPassword(
          email: email,
          password: testPassword,
        );

        // Update display name in Firebase Auth
        await authRepository.updateDisplayName(displayName: displayName);

        // Create user document in Firestore
        final user = AppUser(
          uid: userCredential.user!.uid,
          email: email,
          displayName: displayName,
          role: role,
        );

        await userRepository.createUser(user);
      } catch (createError) {
        throw Exception('Failed to create test account: $createError');
      }
    }
  }

  /// Create all test accounts in Firebase Auth and Firestore
  ///
  /// This seeds the database with test users for all roles
  /// Skips accounts that already exist
  Future<void> seedTestAccounts() async {
    for (final entry in _testAccounts.entries) {
      final role = entry.key;
      final credentials = entry.value;
      final email = credentials['email']!;
      final displayName = credentials['displayName']!;

      try {
        // Try to create the account
        final userCredential = await authRepository.createUserWithEmailAndPassword(
          email: email,
          password: testPassword,
        );

        // Update display name
        await authRepository.updateDisplayName(displayName: displayName);

        // Create user document
        final user = AppUser(
          uid: userCredential.user!.uid,
          email: email,
          displayName: displayName,
          role: role,
        );

        await userRepository.createUser(user);
      } catch (e) {
        // Account likely already exists, skip
        continue;
      }
    }
  }

  /// Check if a test account exists for the given role
  Future<bool> testAccountExists(UserRole role) async {
    if (role == UserRole.guest) {
      return false;
    }

    final credentials = _testAccounts[role];
    if (credentials == null) {
      return false;
    }

    try {
      await authRepository.signInWithEmailAndPassword(
        email: credentials['email']!,
        password: testPassword,
      );
      await authRepository.signOut(); // Sign out immediately after check
      return true;
    } catch (e) {
      return false;
    }
  }
}