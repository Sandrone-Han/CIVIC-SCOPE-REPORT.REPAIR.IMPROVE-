import 'package:civic_scope/core/utils/constants/enums.dart';
import 'package:civic_scope/shared/providers/auth_provider.dart';
import 'package:civic_scope/shared/providers/theme_provider.dart';
import 'package:civic_scope/shared/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/routing/app_routes.dart';

/// This is settings_page.dart

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final currentUserRole = ref.watch(currentUserRoleProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        iconTheme: IconThemeData(color: scheme.onPrimary),
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: false,
        leadingWidth: 40,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            //  Appearance ---------------------
            Text(
              'Appearance',
              style: text.titleMedium?.copyWith(color: scheme.primary),
            ),
            const SizedBox(height: 8),
            _card(
              context,
              child: ListTile(
                leading: Transform.scale(
                  scaleX: -1,
                  child: Icon(Icons.brightness_6, color: scheme.primary),
                ),
                title: const Text('Theme'),
                trailing: DropdownButton<ThemeMode>(
                  value: themeMode,
                  underline: const SizedBox(),
                  dropdownColor: scheme.surface,
                  items: const [
                    DropdownMenuItem(
                      value: ThemeMode.system,
                      child: Text('System'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.light,
                      child: Text('Light'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.dark,
                      child: Text('Dark'),
                    ),
                  ],
                  onChanged: (picked) {
                    if (picked != null) {
                      ref.read(themeModeProvider.notifier).setTheme(picked);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            //  Account ---------------------
            Text(
              'Account',
              style: text.titleMedium?.copyWith(color: scheme.primary),
            ),
            const SizedBox(height: 8),
            // Log In / Sign Up (only show when guest)
            if (currentUserRole == UserRole.guest)
              _card(
                context,
                child: ListTile(
                  leading: Icon(Icons.login, color: scheme.primary),
                  title: const Text('Log In / Sign Up'),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: scheme.outline,
                  ),
                  onTap: () {
                    ref.read(signOutProvider).call(); // Ensure any existing session is cleared
                    context.replace(AppRoutes.authWelcome);
                  },
                ),
              ),

            // Profile (only show when logged in)
            if (currentUserRole != UserRole.guest) ...[
              _card(
                context,
                child: ListTile(
                  leading: Icon(Icons.person_outlined, color: scheme.primary),
                  title: const Text('Profile'),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: scheme.outline,
                  ),
                  onTap: () => context.push('/profile'),
                ),
              ),
            ],

            // Bookmarked (only show when not (citizen & guest))
            if (currentUserRole != UserRole.citizen &&
                currentUserRole != UserRole.guest) ...[
              _card(
                context,
                child: ListTile(
                  leading: Icon(
                    Icons.bookmarks_outlined,
                    color: scheme.primary,
                  ),
                  title: const Text('Bookmarked'),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: scheme.outline,
                  ),
                  onTap: () => context.push('/bookmarks'),
                ),
              ),
            ],

            // Log Out (only show when logged in)
            if (currentUserRole != UserRole.guest) ...[
              _card(
                context,
                child: ListTile(
                  leading: Icon(Icons.logout, color: scheme.error),
                  title: Text('Log Out', style: TextStyle(color: scheme.error)),
                  onTap: () {
                    ref.read(signOutProvider).call();
                  },
                ),
              ),
            ],

          ],
        ),
      ),
    );
  }

  Widget _card(BuildContext context, {required Widget child}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: child,
    );
  }
}
