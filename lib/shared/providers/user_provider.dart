import 'package:civic_scope/core/utils/constants/enums.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/authentication/repositories/user_repository.dart';
import '../../features/authentication/domain/user_model.dart';
import 'auth_provider.dart';

// ============================================================================
// USER DATA PROVIDERS
// ============================================================================
// These providers expose user data from Firestore reactively.
// Watch these in UI to display user information and react to changes.
// ============================================================================

/// Stream of current user's Firestore data (AppUser)
///
/// Returns null if:
/// - User is not authenticated
/// - User document doesn't exist in Firestore
///
/// Watch this provider to display user information in the UI
/// The stream automatically updates when user data changes
///
/// Example:
/// ```dart
/// final currentUser = ref.watch(currentUserProvider);
/// currentUser.when(
///   data: (user) => Text('Hello ${user?.displayName ?? "Guest"}'),
///   loading: () => CircularProgressIndicator(),
///   error: (err, stack) => Text('Error: $err'),
/// );
/// ```
final currentUserProvider = StreamProvider<AppUser?>((ref) {
  final userId = ref.watch(currentUserIdProvider);

  // If not authenticated, return null stream
  if (userId == null) {
    return Stream.value(null);
  }

  // Stream user data from Firestore
  final userRepo = ref.watch(userRepositoryProvider);
  return userRepo.getUserStream(userId);
});

/// Current user's role
///
/// Returns the UserRole of the currently authenticated user, or null if:
/// - User is not authenticated
/// - User data is still loading
/// - User document doesn't exist
///
/// Useful for role-based UI rendering and access control
///
/// Example:
/// ```dart
/// final role = ref.watch(currentUserRoleProvider);
/// if (role == UserRole.admin) {
///   return AdminPanel();
/// }
/// ```
final currentUserRoleProvider = Provider<UserRole>((ref) {
  final asyncUser = ref.watch(currentUserProvider);

  return asyncUser.when(
    data: (user) => user?.role ?? UserRole.guest,
    loading: () => UserRole.guest,
    error: (_, __) => UserRole.guest,
  );
});

/// Current user's display name
///
/// Returns the display name of the currently authenticated user, or null if not available
///
/// Example:
/// ```dart
/// final displayName = ref.watch(currentUserDisplayNameProvider);
/// Text('Welcome ${displayName ?? "User"}');
/// ```
final currentUserDisplayNameProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider);
  return user.value?.displayName;
});

/// Current user's email
///
/// Returns the email of the currently authenticated user, or null if not available
final currentUserEmailProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider);
  return user.value?.email;
});

/// Current user's companyId from Firestore profile.
///
/// Returns null when user is not authenticated or not assigned to any company.
final currentUserCompanyIdProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider);
  return user.value?.companyId;
});
