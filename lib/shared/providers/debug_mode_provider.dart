import 'package:civic_scope/shared/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'shared_preferences_provider.dart';

// ============================================================================
// DEBUG MODE PROVIDER
// ============================================================================
// Controls access to debug/debug features like the role selector
// ============================================================================

/// Key used to store debug mode state in SharedPreferences
const _debugModeKey = 'debug_mode';

/// Debug mode state provider
///
/// When enabled, provides access to:
/// - Role selector screen for testing different user roles
/// - Quick sign-in with test accounts
/// - Additional debugging tools
///
/// Default: false (disabled)
/// Persisted via SharedPreferences

final debugModeProvider = NotifierProvider<DebugModeNotifier, bool>(() {
  return DebugModeNotifier();
});

/// Notifier for managing debug mode state
class DebugModeNotifier extends Notifier<bool> {
  SharedPreferences get prefs => ref.read(sharedPreferencesProvider);
  void Function() get signOut => ref.read(signOutProvider);

  @override
  bool build() {
    //if (!prefs.containsKey(_debugModeKey)) {
      // Initialize debug mode to false if not set
      prefs.setBool(_debugModeKey, false);
    //}
    return prefs.getBool(_debugModeKey) ?? false;
  }

  /// Enable debug mode
  Future<void> enable() async {
    signOut();
    await prefs.setBool(_debugModeKey, true);
    state = true;
  }

  /// Disable debug mode
  Future<void> disable() async {
    signOut();
    await prefs.setBool(_debugModeKey, false);
    state = false;
  }

  /// Toggle debug mode on/off
  Future<void> toggle() async {
    signOut();
    final newValue = !state;
    await prefs.setBool(_debugModeKey, newValue);
    state = newValue;
  }
}
