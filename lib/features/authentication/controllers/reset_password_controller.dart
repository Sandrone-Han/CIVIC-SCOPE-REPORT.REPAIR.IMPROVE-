import 'package:civic_scope/features/authentication/repositories/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// State for reset password screen
class ResetPasswordState {
  final String code;
  final String email;
  final String newPassword;
  final String confirmPassword;
  final bool isVerifyingCode;
  final bool codeVerified;
  final bool isSubmitting;
  final String? submitError;
  final bool passwordReset;

  const ResetPasswordState({
    this.code = '',
    this.email = '',
    this.newPassword = '',
    this.confirmPassword = '',
    this.isVerifyingCode = false,
    this.codeVerified = false,
    this.isSubmitting = false,
    this.submitError,
    this.passwordReset = false,
  });

  ResetPasswordState copyWith({
    String? code,
    String? email,
    String? newPassword,
    String? confirmPassword,
    bool? isVerifyingCode,
    bool? codeVerified,
    bool? isSubmitting,
    String? submitError,
    bool? passwordReset,
  }) {
    return ResetPasswordState(
      code: code ?? this.code,
      email: email ?? this.email,
      newPassword: newPassword ?? this.newPassword,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      isVerifyingCode: isVerifyingCode ?? this.isVerifyingCode,
      codeVerified: codeVerified ?? this.codeVerified,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitError: submitError,
      passwordReset: passwordReset ?? this.passwordReset,
    );
  }
}

/// Controller for reset password screen
class ResetPasswordController extends Notifier<ResetPasswordState> {
  @override
  ResetPasswordState build() {
    return const ResetPasswordState();
  }

  // Getter for easy access to auth repository
  AuthRepository get _authRepo => ref.read(authRepositoryProvider);

  /// Verify the reset code from deep link
  Future<bool> verifyCode(String code) async {
    state = state.copyWith(
      code: code,
      isVerifyingCode: true,
      submitError: null,
    );

    try {
      final email = await _authRepo.verifyPasswordResetCode(code: code);

      state = state.copyWith(
        email: email,
        isVerifyingCode: false,
        codeVerified: true,
        submitError: null,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isVerifyingCode: false,
        codeVerified: false,
        submitError: e.message ?? 'Invalid or expired reset link',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isVerifyingCode: false,
        codeVerified: false,
        submitError: 'Something went wrong, please try again.',
      );
      return false;
    }
  }

  void updateNewPassword(String password) {
    state = state.copyWith(newPassword: password);
  }

  void updateConfirmPassword(String password) {
    state = state.copyWith(confirmPassword: password);
  }

  /// Reset password with the verified code
  Future<bool> resetPassword() async {
    state = state.copyWith(isSubmitting: true, submitError: null);

    try {
      await _authRepo.confirmPasswordReset(
            code: state.code,
            newPassword: state.newPassword,
          );

      state = state.copyWith(
        isSubmitting: false,
        passwordReset: true,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        submitError: e.message ?? 'Failed to reset password',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        submitError: 'Something went wrong, please try again.',
      );
      return false;
    }
  }

  void reset() {
    state = const ResetPasswordState();
  }
}

final resetPasswordControllerProvider =
    NotifierProvider<ResetPasswordController, ResetPasswordState>(
  ResetPasswordController.new,
);
