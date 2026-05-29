import 'package:civic_scope/core/utils/constants/enums.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/user_model.dart';

// Repository provider for dependency injection
final userRepositoryProvider = Provider<UserRepository>((ref) => UserRepository());

/// Repository class that handles all user data operations with Firestore
/// Following the data layer pattern in the app architecture
class UserRepository {
  final FirebaseFirestore _firestore;

  UserRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Returns a reference to the users collection in Firestore
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  // ============================================================================
  // CREATE
  // ============================================================================

  /// Creates a new user document in Firestore
  ///
  /// Uses the user's UID as the document ID
  /// Throws [FirebaseException] if the operation fails
  Future<void> createUser(AppUser user) async {
    await _usersCollection.doc(user.uid).set(user.toMap());
  }

  // ============================================================================
  // READ
  // ============================================================================

  /// Fetches a user document by UID
  ///
  /// Returns the AppUser if found, null if the user doesn't exist
  /// Throws [FirebaseException] if the operation fails
  Future<AppUser?> getUserById(String uid) async {
    final doc = await _usersCollection.doc(uid).get();

    if (!doc.exists) return null;

    return AppUser.fromMap(doc.data()!);
  }

  /// Returns a stream of user data that updates in real-time
  ///
  /// Listens to Firestore changes and emits AppUser whenever the user data changes
  /// Returns null if the user document doesn't exist
  /// Useful for reactive UI updates
  Stream<AppUser?> getUserStream(String uid) {
    return _usersCollection.doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return AppUser.fromMap(doc.data()!);
    });
  }

  // ============================================================================
  // UPDATE
  // ============================================================================

  /// Updates an existing user document in Firestore
  ///
  /// Uses the user's UID to locate the document
  /// Throws [FirebaseException] if the operation fails
  Future<void> updateUser(AppUser user) async {
    await _usersCollection.doc(user.uid).update(user.toMap());
  }

  /// Updates only the role field of a user
  ///
  /// More efficient than updating the entire user document
  /// Throws [FirebaseException] if the operation fails
  Future<void> updateUserRole(String uid, UserRole role) async {
    await _usersCollection.doc(uid).update({'role': role.name});
  }

  // ============================================================================
  // DELETE
  // ============================================================================

  /// Deletes a user document from Firestore
  ///
  /// NOTE: This only deletes the Firestore user data, not the Firebase Auth user
  /// Throws [FirebaseException] if the operation fails
  Future<void> deleteUser(String uid) async {
    await _usersCollection.doc(uid).delete();
  }
}