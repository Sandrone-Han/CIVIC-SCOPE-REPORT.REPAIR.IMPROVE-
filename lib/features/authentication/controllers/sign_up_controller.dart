import 'package:civic_scope/core/utils/constants/enums.dart';
import 'package:civic_scope/features/authentication/domain/user_model.dart';
import 'package:civic_scope/features/authentication/repositories/auth_repository.dart';
import 'package:civic_scope/features/authentication/repositories/user_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Form state for signup
class SignUpState {
  final String name;
  final String email;
  final String password;
  final String confirmPassword;
  final bool isSubmitting;
  final String? submitError;
  final bool submitSuccess;

  const SignUpState({
    this.name = '',
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.isSubmitting = false,
    this.submitError,
    this.submitSuccess = false,
  });

  SignUpState copyWith({
    String? name,
    String? email,
    String? password,
    String? confirmPassword,
    bool? isSubmitting,
    String? submitError,
    bool? submitSuccess,
  }) {
    return SignUpState(
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitError: submitError,
      submitSuccess: submitSuccess ?? this.submitSuccess,
    );
  }
}

/// Form controller for signup
class SignUpController extends Notifier<SignUpState> {
  @override
  SignUpState build() {
    return const SignUpState();
  }

  // Getter for easy access to auth repository
  AuthRepository get _authRepo => ref.read(authRepositoryProvider);
  UserRepository get _userRepo => ref.read(userRepositoryProvider);

  void updateName(String name) {
    state = state.copyWith(name: name);
  }

  void updateEmail(String email) {
    state = state.copyWith(email: email);
  }

  void updatePassword(String password) {
    state = state.copyWith(password: password);
  }

  void updateConfirmPassword(String confirmPassword) {
    state = state.copyWith(confirmPassword: confirmPassword);
  }

  Future<bool> signUp() async {
    state = state.copyWith(isSubmitting: true, submitError: null);

    try {
      // Create user account
      UserCredential newUser = await _authRepo.createUserWithEmailAndPassword(
        email: state.email,
        password: state.password
      );

      // Update display name
      if (state.name.isNotEmpty) {
        await _authRepo.updateDisplayName(displayName: state.name);
      }
  
      // Create user document in Firestore
      await _userRepo.createUser(AppUser(
        uid: newUser.user!.uid,
        email: state.email,
        displayName: state.name,
        role: UserRole.citizen));

      state = state.copyWith(
        isSubmitting: false,
        submitSuccess: true,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        submitError: e.message ?? 'Failed to create account',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        submitError: e.toString(),
      );
      return false;
    }
  }

  void reset() {
    state = const SignUpState();
  }
}

final signUpControllerProvider =
    NotifierProvider<SignUpController, SignUpState>(
  SignUpController.new,
);
