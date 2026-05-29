import 'dart:async';

import 'package:civic_scope/core/utils/constants/enums.dart';
import 'package:civic_scope/features/authentication/domain/user_model.dart';
import 'package:civic_scope/features/authentication/repositories/user_repository.dart';

class FakeUserRepository implements UserRepository {
  FakeUserRepository({Iterable<AppUser> initialUsers = const []}) {
    for (final user in initialUsers) {
      _users[user.uid] = user;
    }
  }

  final Map<String, AppUser> _users = <String, AppUser>{};
  final Map<String, StreamController<AppUser?>> _controllers =
      <String, StreamController<AppUser?>>{};

  int createUserCallCount = 0;
  int updateUserCallCount = 0;
  int updateUserRoleCallCount = 0;
  int deleteUserCallCount = 0;

  AppUser? lastCreatedUser;
  AppUser? lastUpdatedUser;
  String? lastDeletedUserId;

  StreamController<AppUser?> _controllerFor(String uid) {
    return _controllers.putIfAbsent(
      uid,
      () => StreamController<AppUser?>.broadcast(),
    );
  }

  void seedUser(AppUser user) {
    _users[user.uid] = user;
    _controllerFor(user.uid).add(user);
  }

  void dispose() {
    for (final controller in _controllers.values) {
      controller.close();
    }
  }

  @override
  Future<void> createUser(AppUser user) async {
    createUserCallCount += 1;
    lastCreatedUser = user;
    _users[user.uid] = user;
    _controllerFor(user.uid).add(user);
  }

  @override
  Future<AppUser?> getUserById(String uid) async => _users[uid];

  @override
  Stream<AppUser?> getUserStream(String uid) async* {
    yield _users[uid];
    yield* _controllerFor(uid).stream;
  }

  @override
  Future<void> updateUser(AppUser user) async {
    updateUserCallCount += 1;
    lastUpdatedUser = user;
    _users[user.uid] = user;
    _controllerFor(user.uid).add(user);
  }

  @override
  Future<void> updateUserRole(String uid, UserRole role) async {
    updateUserRoleCallCount += 1;
    final current = _users[uid];
    if (current == null) return;
    final updated = current.copyWith(role: role);
    _users[uid] = updated;
    _controllerFor(uid).add(updated);
  }

  @override
  Future<void> deleteUser(String uid) async {
    deleteUserCallCount += 1;
    lastDeletedUserId = uid;
    _users.remove(uid);
    _controllerFor(uid).add(null);
  }
}
