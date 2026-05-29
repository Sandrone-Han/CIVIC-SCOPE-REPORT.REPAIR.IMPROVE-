import 'package:civic_scope/features/authentication/repositories/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Form state for forgot password 
class ForgotPasswordState {
  final String email;
  final bool emailSent;
  final bool isSubmitting;
  final String? submitError;

  const ForgotPasswordState({
    this.email = '',
    this.emailSent = false,
    this.isSubmitting = false,
    this.submitError
  });

  ForgotPasswordState copyWith({
    String? email,
    bool? emailSent,
    bool? isSubmitting,
    String? submitError
  }) {
    return ForgotPasswordState(
      email: email ?? this.email,
      emailSent: emailSent ?? this.emailSent,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitError: submitError ?? this.submitError
    );
  }
}

/// Form controller for forgot password
class ForgotPasswordController extends Notifier<ForgotPasswordState> {
  @override
  ForgotPasswordState build() {
    return const ForgotPasswordState();
  }

  // Getter for easy access to auth repository
  AuthRepository get _authRepo => ref.read(authRepositoryProvider);

  // Update email
  void updateEmail(String email) {
    state = state.copyWith(email: email);
  }

  /// Send password reset email with deep link
  ///
  /// The email will contain a link that opens the app,
  /// allowing the user to reset their password within the app.
  Future<bool> sendEmail() async {
    state = state.copyWith(isSubmitting: true, submitError: null);

    try {
      await _authRepo.sendPasswordResetEmail(email: state.email);

      state = state.copyWith(
        isSubmitting: false,
        emailSent: true,
      );
      
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        submitError: e.message ?? 'Failed to send reset email',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        submitError: 'Something went wrong, try again.',
      );
      return false;
    }
  }

  void reset() {
    state = const ForgotPasswordState();
  }
}

final forgotPasswordControllerProvider =
    NotifierProvider<ForgotPasswordController, ForgotPasswordState>(
  ForgotPasswordController.new,
);
