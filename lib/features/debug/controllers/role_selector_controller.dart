import 'package:civic_scope/core/utils/constants/enums.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/test_accounts_repository.dart';

/// State for role selector screen
class RoleSelectorState {
  final bool isSeeding;
  final bool isSigningIn;
  final String? error;
  final String? success;


  const RoleSelectorState({
    this.isSeeding = false,
    this.isSigningIn = false,
    this.error,
    this.success,
  });

  RoleSelectorState copyWith({
    bool? isSeeding,
    bool? isSigningIn,
    String? error,
    String? success,
  }) {
    return RoleSelectorState(
      isSeeding: isSeeding ?? this.isSeeding,
      isSigningIn: isSigningIn ?? this.isSigningIn,
      error: error,
      success: success,
    );
  }
}

/// Controller for role selector screen
class RoleSelectorController extends Notifier<RoleSelectorState> {
  @override
  RoleSelectorState build() {
    return const RoleSelectorState();
  }

  // Getter for easy access to test accounts repository
  TestAccountsRepository get _testRepo =>
      ref.read(testAccountsRepositoryProvider);

  /// Seeds test accounts in Firebase (if not already seeded)
  Future<void> seedTestAccountsIfNeeded() async {
    state = state.copyWith(isSeeding: true, error: null);

    try {
      await _testRepo.seedTestAccounts();
      state = state.copyWith(isSeeding: false);
    } catch (e) {
      state = state.copyWith(
        isSeeding: false,
        error: 'Failed to seed test accounts: $e',
      );
    }
  }

  /// Sign in as a specific user role using test account
  Future<bool> signInAs(UserRole role) async {
    state = state.copyWith(isSigningIn: true, error: null);

    try {
      await _testRepo.signInAsTestUser(role);
      String testName, testEmail;
      [testName, testEmail] = _testRepo.getTestCredentials(role)!.values.toList();
      state = state.copyWith(
        isSigningIn: false,
        success: 'Signed in as $testName ($testEmail)',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSigningIn: false,
        error: 'Failed to sign in as ${role.name}: $e',
      );
      return false;
    }
  }

  /// Clear any error messages
  void clearError() {
    state = state.copyWith(error: null);
  }
}

final roleSelectorControllerProvider =
    NotifierProvider<RoleSelectorController, RoleSelectorState>(
  RoleSelectorController.new,
);
