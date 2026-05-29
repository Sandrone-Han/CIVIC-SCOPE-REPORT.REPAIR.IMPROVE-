import 'package:civic_scope/core/utils/constants/enums.dart';
import 'package:civic_scope/shared/providers/debug_mode_provider.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/hooks/use_state_listener.dart';
import '../controllers/role_selector_controller.dart';

/// Role selector screen for debug/testing mode
///
/// Allows quick switching between user roles by signing in with
/// pre-configured test accounts. Only accessible when debug mode is enabled.
class RoleSelectorScreen extends HookConsumerWidget {
  const RoleSelectorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final controller = ref.read(roleSelectorControllerProvider.notifier);
    final state = ref.watch(roleSelectorControllerProvider);

    // Use custom hook to show error messages as snackbars from controller
    useStateListener(
      ref: ref,
      provider: roleSelectorControllerProvider,
      onError: (state) => state.error,
      onSuccess: (state) => state.success,
    );

    // Navigate to auth loading when signing in starts
    ref.listen(roleSelectorControllerProvider, (previous, next) {
      if (next.isSigningIn && !(previous?.isSigningIn ?? false)) {
        print('Signing in...'); // Debug print
        context.replace(AppRoutes.authLoading);
      }
    });

    // Uncomment to seed test accounts on mount
    // useEffect(() {
    //   controller.seedTestAccountsIfNeeded();
    //   return null;
    // }, []);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: scheme.error, // Use error color to indicate debug mode
        foregroundColor: scheme.onError,
        iconTheme: IconThemeData(color: scheme.onError),
        title: Row(
          children: [
            const Icon(Icons.bug_report),
            const SizedBox(width: 8),
            SvgPicture.asset(
              'assets/civic_scope_banner.svg',
              height: 60,
              colorFilter: ColorFilter.mode(scheme.onError, BlendMode.srcIn),
            ),
          ],
        ),
        centerTitle: false,
        leadingWidth: 40,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: state.isSeeding
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Setting up test accounts...'),
                ],
              ),
            )
          : Column(
              children: [
                // Debug Mode Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: scheme.error,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.warning, color: scheme.onError, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'DEBUG MODE ACTIVE',
                        style: TextStyle(
                          color: scheme.onError,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),

                // Error Message
                if (state.error != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    color: scheme.errorContainer,
                    child: Text(
                      state.error!,
                      style: TextStyle(color: scheme.onErrorContainer),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Role Buttons
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Select a role to test:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Citizen
                          _buildRoleButton(
                            context,
                            role: UserRole.citizen,
                            label: 'Launch as Citizen',
                            isSigningIn: state.isSigningIn,
                            onPressed: () =>
                                controller.signInAs(UserRole.citizen),
                          ),

                          // Worker
                          _buildRoleButton(
                            context,
                            role: UserRole.worker,
                            label: 'Launch as Worker',
                            isSigningIn: state.isSigningIn,
                            onPressed: () =>
                                controller.signInAs(UserRole.worker),
                          ),

                          // Company
                          _buildRoleButton(
                            context,
                            role: UserRole.company,
                            label: 'Launch as Company',
                            isSigningIn: state.isSigningIn,
                            onPressed: () =>
                                controller.signInAs(UserRole.company),
                          ),

                          // Council
                          _buildRoleButton(
                            context,
                            role: UserRole.council,
                            label: 'Launch as Council',
                            isSigningIn: state.isSigningIn,
                            onPressed: () =>
                                controller.signInAs(UserRole.council),
                          ),

                          // Admin
                          _buildRoleButton(
                            context,
                            role: UserRole.admin,
                            label: 'Launch as Admin',
                            isSigningIn: state.isSigningIn,
                            onPressed: () =>
                                controller.signInAs(UserRole.admin),
                          ),

                          const SizedBox(height: 24),

                          // Back to App Button
                          OutlinedButton.icon(
                            onPressed: () => ref
                                .read(debugModeProvider.notifier)
                                .disable(),
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('Back to Welcome'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildRoleButton(
    BuildContext context, {
    required UserRole role,
    required String label,
    required bool isSigningIn,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 18),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: Text(label),
        ),
      ),
    );
  }
}
