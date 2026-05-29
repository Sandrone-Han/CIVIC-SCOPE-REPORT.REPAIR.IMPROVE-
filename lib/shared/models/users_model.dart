import 'package:civic_scope/core/utils/constants/enums.dart';

/// User model representing a user in the Civic-Scope application
/// Stores user information from Firebase Auth and Firestore
class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final UserRole role; // Stored in database as enum name.
  final String? companyId; // Optional field for company association

  AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    this.companyId,
  });

  /// Converts a AppUser instance to a Map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'role': role.name,
      'companyId': companyId,
    };
  }

  /// Creates a AppUser instance from a Firestore document map
  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] as String,
      email: map['email'] as String,
      displayName: map['displayName'] as String,
      role: UserRole.values.firstWhere((e) => e.name == map['role'] as String),
      companyId: map['companyId'] as String?,
    );
  }

  /// Creates a copy of this AppUser with the given fields replaced
  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    UserRole? role,
    String? companyId,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      companyId: companyId ?? this.companyId,
    );
  }

  @override
  String toString() {
    return 'AppUser(uid: $uid, email: $email, displayName: $displayName, role: ${role.name})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AppUser && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}