import 'package:civic_scope/core/utils/constants/enums.dart';
import 'package:civic_scope/features/authentication/repositories/auth_repository.dart';
import 'package:civic_scope/shared/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository fakeAuthRepository;
  late ProviderContainer container;

  setUp(() {
    fakeAuthRepository = FakeAuthRepository();
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(fakeAuthRepository)],
    );
  });

  tearDown(() {
    fakeAuthRepository.dispose();
    container.dispose();
  });
   
  test('signOutProvider delegates to the repository signOut method', () async {
    container.read(signOutProvider).call();

    expect(fakeAuthRepository.signOutCallCount, 1);
  });
}
