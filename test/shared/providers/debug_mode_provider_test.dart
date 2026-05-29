import 'package:civic_scope/shared/providers/auth_provider.dart';
import 'package:civic_scope/shared/providers/debug_mode_provider.dart';
import 'package:civic_scope/shared/providers/shared_preferences_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_preferences.dart';

void main() {
  test('enable, disable and toggle persist debug mode and invoke sign out', () async {
    final prefs = await setUpTestPrefs();
    var signOutCount = 0;

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        signOutProvider.overrideWithValue(() {
          signOutCount += 1;
        }),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(debugModeProvider), isFalse);

    await container.read(debugModeProvider.notifier).enable();
    expect(container.read(debugModeProvider), isTrue);
    expect(prefs.getBool('debug_mode'), isTrue);

    await container.read(debugModeProvider.notifier).toggle();
    expect(container.read(debugModeProvider), isFalse);
    expect(prefs.getBool('debug_mode'), isFalse);

    await container.read(debugModeProvider.notifier).disable();
    expect(container.read(debugModeProvider), isFalse);
    expect(signOutCount, 3);
  });
}
