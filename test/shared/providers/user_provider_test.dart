import 'package:civic_scope/core/utils/constants/enums.dart';
import 'package:civic_scope/features/authentication/domain/user_model.dart';
import 'package:civic_scope/shared/providers/user_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('currentUserProvider emits null when no authenticated user id exists', () async {
    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWith(
          (ref) => Stream<AppUser?>.fromIterable(const [null]),
        ),
      ],
    );
    addTearDown(container.dispose);

    final sub = container.listen<AsyncValue<AppUser?>>(
      currentUserProvider,
      (previous, next) {},
      fireImmediately: true,
    );
    addTearDown(sub.close);

    await Future<void>.delayed(const Duration(milliseconds: 1));

    expect(container.read(currentUserProvider).value, isNull);
    expect(container.read(currentUserRoleProvider), UserRole.guest);
    expect(container.read(currentUserDisplayNameProvider), isNull);
    expect(container.read(currentUserEmailProvider), isNull);
    expect(container.read(currentUserCompanyIdProvider), isNull);
  });

  test('derived providers expose role, display name, email and company id', () async {
    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWith(
          (ref) => Stream<AppUser?>.fromIterable([
            AppUser(
              uid: 'u-1',
              email: 'company@example.com',
              displayName: 'Company User',
              role: UserRole.company,
              companyId: 'comp-77',
            ),
          ]),
        ),
      ],
    );
    addTearDown(container.dispose);

    final sub = container.listen<AsyncValue<AppUser?>>(
      currentUserProvider,
      (previous, next) {},
      fireImmediately: true,
    );
    addTearDown(sub.close);

    await Future<void>.delayed(const Duration(milliseconds: 1));

    expect(container.read(currentUserProvider).value?.displayName, 'Company User');
    expect(container.read(currentUserRoleProvider), UserRole.company);
    expect(container.read(currentUserDisplayNameProvider), 'Company User');
    expect(container.read(currentUserEmailProvider), 'company@example.com');
    expect(container.read(currentUserCompanyIdProvider), 'comp-77');
  });
}