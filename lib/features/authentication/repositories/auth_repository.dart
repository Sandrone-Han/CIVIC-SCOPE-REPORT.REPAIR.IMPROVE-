import 'package:civic_scope/core/utils/constants/enums.dart';
import 'package:civic_scope/features/authentication/domain/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


// Repository provider for dependency injection
final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());

/// Repository class that handles all authentication operations
/// Following the data layer pattern in the app architecture
class AuthRepository {
  final FirebaseAuth _firebaseAuth;

  AuthRepository({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  // ============================================================================
  // GETTERS
  // ============================================================================

  /// Returns the currently authenticated user, or null if not authenticated
  User? get currentUser => _firebaseAuth.currentUser;

  AppUser? get currentAppUser {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return null;

    return AppUser(
      uid: firebaseUser.uid,
      email: firebaseUser.email!,
      displayName: firebaseUser.displayName!,
      role: UserRole.citizen,
      companyId: null,
    );
  }

  /// Stream that emits the current user whenever auth state changes
  Stream<User?> get firebaseAuthUserChanges => _firebaseAuth.authStateChanges();

  /// Returns the current user's UID, or null if not authenticated
  String? get currentUserId => _firebaseAuth.currentUser?.uid;

  // ============================================================================
  // SIGN IN METHODS
  // ============================================================================

  /// Sign in with email and password
  ///
  /// Throws [FirebaseAuthException] if sign in fails
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // ============================================================================
  // SIGN UP METHODS
  // ============================================================================

  /// Create a new user account with email and password
  ///
  /// Throws [FirebaseAuthException] if account creation fails
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // ============================================================================
  // SIGN OUT
  // ============================================================================

  /// Sign out the current user
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  // ============================================================================
  // PASSWORD MANAGEMENT
  // ============================================================================

  /// Send password reset email to the specified email address
  ///
  /// The email contains a link that opens the app via deep linking,
  /// allowing the user to reset their password within the app.
  ///
  /// Throws [FirebaseAuthException] if the operation fails
  Future<void> sendPasswordResetEmail({
    required String email,
  }) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  /// Verify a password reset code from a deep link
  ///
  /// Call this after extracting the oobCode from a password reset deep link
  /// to verify the code is valid before showing the reset password screen.
  ///
  /// Returns the email associated with the reset code.
  /// Throws [FirebaseAuthException] if the code is invalid or expired
  Future<String> verifyPasswordResetCode({
    required String code,
  }) async {
    return await _firebaseAuth.verifyPasswordResetCode(code);
  }

  /// Confirm password reset with the code from deep link
  ///
  /// Use this after the user clicks the reset link in their email.
  /// The link contains an oobCode that must be extracted and passed here
  /// along with the new password the user chose.
  ///
  /// Throws [FirebaseAuthException] if the code is invalid or expired
  Future<void> confirmPasswordReset({
    required String code,
    required String newPassword,
  }) async {
    await _firebaseAuth.confirmPasswordReset(
      code: code,
      newPassword: newPassword,
    );
  }

  // ============================================================================
  // EMAIL VERIFICATION
  // ============================================================================

  /// Send email verification to the current user
  ///
  /// Throws [FirebaseAuthException] if no user is signed in
  Future<void> sendEmailVerification() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No user is currently signed in',
      );
    }
    await user.sendEmailVerification();
  }

  /// Check if the current user's email is verified
  bool get isEmailVerified => _firebaseAuth.currentUser?.emailVerified ?? false;


  /// Reload current user to get latest data (including email verification status)
  Future<void> reloadUser() async {
    await _firebaseAuth.currentUser?.reload();
  }

  // ============================================================================
  // PROFILE MANAGEMENT
  // ============================================================================

  /// Update the current user's display name
  Future<void> updateDisplayName({
    required String displayName,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No user is currently signed in',
      );
    }
    await user.updateDisplayName(displayName);
  }

  /// Update the current user's photo URL
  Future<void> updatePhotoURL({
    required String photoURL,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No user is currently signed in',
      );
    }
    await user.updatePhotoURL(photoURL);
  }

  /// Update the current user's email address
  ///
  /// Requires recent authentication. May throw [FirebaseAuthException]
  Future<void> updateEmail({
    required String newEmail,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No user is currently signed in',
      );
    }
    await user.verifyBeforeUpdateEmail(newEmail);
  }

  // ============================================================================
  // ACCOUNT DELETION
  // ============================================================================

  /// Delete the current user's account
  ///
  /// Requires recent authentication. May throw [FirebaseAuthException]
  /// NOTE: This only deletes the Firebase Auth user, not Firestore data
  Future<void> deleteAccount() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No user is currently signed in',
      );
    }
    await user.delete();
  }

  // ============================================================================
  // RE-AUTHENTICATION
  // ============================================================================

  /// Re-authenticate the current user with email and password
  ///
  /// Required before sensitive operations like password change or account deletion
  Future<UserCredential> reauthenticateWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No user is currently signed in',
      );
    }

    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );

    return await user.reauthenticateWithCredential(credential);
  }
}