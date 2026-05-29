import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/routing/app_routes.dart';
import '../../../shared/providers/debug_mode_provider.dart';

/// Welcome screen shown to unauthenticated users
///
/// Provides options to:
/// - Continue as Guest (view-only access)
/// - Sign In (existing users)
/// - Sign Up (new users)
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final debugMode = ref.watch(debugModeProvider);

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          // Debug Mode Toggle Button
          IconButton(
            iconSize: 40,
            icon: Icon(
              debugMode ? Icons.bug_report : Icons.bug_report_outlined,
              color: debugMode
                  ? scheme.error
                  : scheme.onSurface.withValues(alpha: 0.6),
            ),
            tooltip: 'Debug Mode',
            onPressed: () async {
              if (!debugMode) {
                // Show warning dialog when enabling
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Enable Debug Mode?'),
                    content: const Text(
                      'This will enable access to the role selector screen for testing different user roles with pre-configured test accounts.\n\n'
                      'Only enable this for development and testing purposes.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Enable'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await ref.read(debugModeProvider.notifier).enable();
                }
              } else {
                await ref.read(debugModeProvider.notifier).disable();
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // App Logo/Banner
              SvgPicture.asset(
                'assets/centered_banner.svg',
                height: 100,
                colorFilter: ColorFilter.mode(scheme.primary, BlendMode.srcIn),
              ),

              // App Tagline
              Text(
                'Report, Track, and Improve\nYour Community',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: scheme.onSurface.withOpacity(0.7),
                  height: 1.5,
                ),
              ),

              const Spacer(flex: 3),

              // Continue as Guest Button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    context.go(AppRoutes.homeMap);
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('Continue as Guest'),
                ),
              ),

              const SizedBox(height: 8),

              // Sign In Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    context.push(AppRoutes.authLogIn);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('Sign In'),
                ),
              ),

              const SizedBox(height: 8),

              // Sign Up Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    context.push(AppRoutes.authSignUp);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('Sign Up'),
                ),
              ),

              const Spacer(flex: 2),

              // Debug Mode Link (only visible if enabled)
              if (debugMode) ...[
                const Divider(),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      context.push(AppRoutes.debugRoleSelector);
                    },
                    icon: Icon(Icons.swap_horiz, color: scheme.error),
                    label: Text(
                      'Test Role Selector',
                      style: TextStyle(color: scheme.error),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: scheme.error),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
