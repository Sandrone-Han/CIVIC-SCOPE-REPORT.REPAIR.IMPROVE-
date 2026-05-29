import 'package:civic_scope/features/authentication/repositories/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Form state with validation
class LogInState {
  final String email;
  final String password;
  final bool isSubmitting;
  final String? submitError;
  final bool submitSuccess;

  const LogInState({
    this.email = '',
    this.password = '',
    this.isSubmitting = false,
    this.submitError,
    this.submitSuccess = false,
  });

  LogInState copyWith({
    String? email,
    String? password,
    bool? isSubmitting,
    String? submitError,
    bool? submitSuccess,
  }) {
    return LogInState(
      email: email ?? this.email,
      password: password ?? this.password,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitError: submitError,
      submitSuccess: submitSuccess ?? this.submitSuccess,
    );
  }
}


/// Form controller with validation logic
class LogInController extends Notifier<LogInState> {
  @override
  LogInState build() {
    return const LogInState();
  }

  // Getter for easy access to auth repository
  AuthRepository get _authRepo => ref.read(authRepositoryProvider);

  void updateEmail(String email) {
    state = state.copyWith(email: email);
  }

  void updatePassword(String password) {
    state = state.copyWith(password: password);
  }

  Future<bool> submit() async {
    state = state.copyWith(isSubmitting: true, submitError: null);

    try {
      // Perform submission
      await _authRepo.signInWithEmailAndPassword(
            email: state.email,
            password: state.password,
          );

      state = state.copyWith(
        isSubmitting: false,
        submitSuccess: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        submitError: e.toString(),
      );
      return false;
    }
  }

  void reset() {
    state = const LogInState();
  }
}

final logInControllerProvider =
    NotifierProvider<LogInController, LogInState>(
  LogInController.new,
);