import 'dart:async';

import 'package:civic_scope/core/utils/constants/enums.dart';
import 'package:civic_scope/features/authentication/domain/user_model.dart';
import 'package:civic_scope/features/authentication/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/mockito.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    User? currentUser,
    AppUser? currentAppUser,
  })  : _currentUser = currentUser,
        _currentAppUser = currentAppUser {
    _authStateController.add(currentUser);
  }

  final StreamController<User?> _authStateController =
      StreamController<User?>.broadcast();

  Future<UserCredential> Function(String email, String password)? signInHandler;
  Future<UserCredential> Function(String email, String password)?
      createUserHandler;
  Future<void> Function(String email)? sendPasswordResetEmailHandler;
  Future<String> Function(String code)? verifyPasswordResetCodeHandler;
  Future<void> Function(String code, String newPassword)?
      confirmPasswordResetHandler;
  Future<void> Function(String displayName)? updateDisplayNameHandler;
  Future<void> Function()? signOutHandler;
  Future<void> Function()? sendEmailVerificationHandler;
  Future<void> Function()? reloadUserHandler;
  Future<void> Function()? deleteAccountHandler;
  Future<void> Function(String newEmail)? updateEmailHandler;
  Future<void> Function(String photoUrl)? updatePhotoUrlHandler;
  Future<UserCredential> Function(String email, String password)?
      reauthenticateHandler;

  int signInCallCount = 0;
  int createUserCallCount = 0;
  int sendPasswordResetEmailCallCount = 0;
  int verifyPasswordResetCodeCallCount = 0;
  int confirmPasswordResetCallCount = 0;
  int updateDisplayNameCallCount = 0;
  int signOutCallCount = 0;
  int sendEmailVerificationCallCount = 0;
  int reloadUserCallCount = 0;
  int deleteAccountCallCount = 0;
  int updateEmailCallCount = 0;
  int updatePhotoUrlCallCount = 0;
  int reauthenticateCallCount = 0;

  String? lastSignInEmail;
  String? lastSignInPassword;
  String? lastCreateUserEmail;
  String? lastCreateUserPassword;
  String? lastResetEmail;
  String? lastVerifiedCode;
  String? lastConfirmedCode;
  String? lastConfirmedNewPassword;
  String? lastDisplayName;
  String? lastUpdatedEmail;
  String? lastUpdatedPhotoUrl;
  String? lastReauthenticateEmail;
  String? lastReauthenticatePassword;

  User? _currentUser;
  AppUser? _currentAppUser;
  bool emailVerified = false;

  void emitUser(User? user, {AppUser? appUser}) {
    _currentUser = user;
    _currentAppUser = appUser;
    _authStateController.add(user);
  }

  void dispose() {
    _authStateController.close();
  }

  @override
  User? get currentUser => _currentUser;

  @override
  AppUser? get currentAppUser {
    if (_currentAppUser != null) {
      return _currentAppUser;
    }

    final user = _currentUser;
    if (user == null) return null;

    return AppUser(
      uid: user.uid,
      email: user.email ?? 'user@example.com',
      displayName: user.displayName ?? 'Test User',
      role: UserRole.citizen,
      companyId: null,
    );
  }

  @override
  Stream<User?> get firebaseAuthUserChanges async* {
    yield _currentUser;
    yield* _authStateController.stream;
  }

  @override
  String? get currentUserId => _currentUser?.uid;

  @override
  bool get isEmailVerified => emailVerified;

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    signInCallCount += 1;
    lastSignInEmail = email;
    lastSignInPassword = password;

    final credential = await (signInHandler?.call(email, password) ??
        Future<UserCredential>.value(DummyUserCredential()));

    if (credential.user != null) {
      emitUser(credential.user);
    }
    return credential;
  }

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    createUserCallCount += 1;
    lastCreateUserEmail = email;
    lastCreateUserPassword = password;

    final credential = await (createUserHandler?.call(email, password) ??
        Future<UserCredential>.value(
          DummyUserCredential(user: DummyUser(uid: 'created-user-id', email: email)),
        ));

    if (credential.user != null) {
      emitUser(credential.user);
    }
    return credential;
  }

  @override
  Future<void> signOut() async {
    signOutCallCount += 1;
    await signOutHandler?.call();
    emitUser(null, appUser: null);
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    sendPasswordResetEmailCallCount += 1;
    lastResetEmail = email;
    await (sendPasswordResetEmailHandler?.call(email) ?? Future<void>.value());
  }

  @override
  Future<String> verifyPasswordResetCode({required String code}) async {
    verifyPasswordResetCodeCallCount += 1;
    lastVerifiedCode = code;
    return await (verifyPasswordResetCodeHandler?.call(code) ??
        Future<String>.value('user@example.com'));
  }

  @override
  Future<void> confirmPasswordReset({
    required String code,
    required String newPassword,
  }) async {
    confirmPasswordResetCallCount += 1;
    lastConfirmedCode = code;
    lastConfirmedNewPassword = newPassword;
    await (confirmPasswordResetHandler?.call(code, newPassword) ??
        Future<void>.value());
  }

  @override
  Future<void> sendEmailVerification() async {
    sendEmailVerificationCallCount += 1;
    await (sendEmailVerificationHandler?.call() ?? Future<void>.value());
    emailVerified = true;
  }

  @override
  Future<void> reloadUser() async {
    reloadUserCallCount += 1;
    await (reloadUserHandler?.call() ?? Future<void>.value());
  }

  @override
  Future<void> updateDisplayName({required String displayName}) async {
    updateDisplayNameCallCount += 1;
    lastDisplayName = displayName;
    await (updateDisplayNameHandler?.call(displayName) ?? Future<void>.value());
  }

  @override
  Future<void> updatePhotoURL({required String photoURL}) async {
    updatePhotoUrlCallCount += 1;
    lastUpdatedPhotoUrl = photoURL;
    await (updatePhotoUrlHandler?.call(photoURL) ?? Future<void>.value());
  }

  @override
  Future<void> updateEmail({required String newEmail}) async {
    updateEmailCallCount += 1;
    lastUpdatedEmail = newEmail;
    await (updateEmailHandler?.call(newEmail) ?? Future<void>.value());
  }

  @override
  Future<void> deleteAccount() async {
    deleteAccountCallCount += 1;
    await (deleteAccountHandler?.call() ?? Future<void>.value());
    emitUser(null, appUser: null);
  }

  @override
  Future<UserCredential> reauthenticateWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    reauthenticateCallCount += 1;
    lastReauthenticateEmail = email;
    lastReauthenticatePassword = password;
    return await (reauthenticateHandler?.call(email, password) ??
        Future<UserCredential>.value(DummyUserCredential(user: _currentUser)));
  }
}

class DummyUser extends Mock implements User {
  DummyUser({
    required String uid,
    String? email,
    String? displayName,
    bool emailVerified = false,
  }) {
    when(this.uid).thenReturn(uid);
    when(this.email).thenReturn(email);
    when(this.displayName).thenReturn(displayName);
    when(this.emailVerified).thenReturn(emailVerified);
  }
}

class DummyUserCredential extends Mock implements UserCredential {
  DummyUserCredential({User? user}) {
    when(this.user).thenReturn(user);
  }
}
