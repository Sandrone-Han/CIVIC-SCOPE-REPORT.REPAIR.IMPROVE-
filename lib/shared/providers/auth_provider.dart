import 'package:civic_scope/core/utils/constants/enums.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/authentication/repositories/auth_repository.dart';

// ============================================================================
// AUTH STATE PROVIDERS
// ============================================================================
// These providers expose authentication state reactively.
// Watch these in UI to react to login/logout events.
// ============================================================================

/// Stream of Firebase Auth user
/// Emits current user when authenticated, null when not authenticated

final firebaseAuthUserProvider = StreamProvider<firebase_auth.User?>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.firebaseAuthUserChanges;
});

/// Overall authentication state of the app
/// Returns an AppAuthState enum value representing the current auth status
final authStateProvider = Provider<AppAuthState>((ref) {
  final authRepo = ref.watch(firebaseAuthUserProvider);
  return authRepo.when(
    data: (firebaseUser) => switch (firebaseUser) {
      null => AppAuthState.unauthenticated,
      _ => AppAuthState.authenticated,
    },
    error: (error, stack) => AppAuthState.error,
    loading: () => AppAuthState.loading);
});


/// Current Firebase Auth user UID
///
/// Returns the UID of the currently authenticated user, or null if not logged in
/// Useful for querying user-specific data from Firestore
final currentUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(firebaseAuthUserProvider);
  return authState.value?.uid;
});

/// Sign out the current user
/// Call this method to log out the user and clear auth state
final signOutProvider = Provider<void Function()>((ref) {
  final authRepo = ref.read(authRepositoryProvider);
  return authRepo.signOut;
});