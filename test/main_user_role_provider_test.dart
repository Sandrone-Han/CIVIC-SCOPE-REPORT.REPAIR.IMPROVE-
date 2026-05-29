import 'dart:async';

import 'package:civic_scope/core/utils/constants/enums.dart';
import 'package:civic_scope/features/authentication/domain/user_model.dart';
import 'package:civic_scope/shared/providers/user_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('currentUserRoleProvider', () {
    test('defaults to guest while user data is unavailable', () {
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => Stream<AppUser?>.value(null)),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(currentUserRoleProvider), UserRole.guest);
    });

    test('updates when the underlying currentUserProvider emits a new role', () async {
      final controller = StreamController<AppUser?>();
      addTearDown(controller.close);

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => controller.stream),
        ],
      );
      addTearDown(container.dispose);

      final observed = <UserRole>[];

      final sub = container.listen<UserRole>(
        currentUserRoleProvider,
        (previous, next) => observed.add(next),
        fireImmediately: true,
      );
      addTearDown(sub.close);

      controller.add(
        AppUser(
          uid: 'u-1',
          email: 'company@example.com',
          displayName: 'Company User',
          role: UserRole.company,
          companyId: 'comp-1',
        ),
      );
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      controller.add(
        AppUser(
          uid: 'u-2',
          email: 'council@example.com',
          displayName: 'Council User',
          role: UserRole.council,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(observed, [
        UserRole.guest,
        UserRole.company,
        UserRole.council,
      ]);
    });
  });
}
