import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:civic_scope/core/utils/validators/validators.dart';
import 'package:civic_scope/core/hooks/use_state_listener.dart';
import 'package:civic_scope/core/routing/app_routes.dart';
import '../controllers/reset_password_controller.dart';

/// Reset Password Screen - shown after clicking email link
/// Receives the oobCode from deep link and allows user to enter new password
class ResetPasswordScreen extends HookConsumerWidget {
  const ResetPasswordScreen({
    super.key,
    required this.code,
  });

  /// The oobCode from the password reset deep link
  final String code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useStateListener(
      ref: ref,
      provider: resetPasswordControllerProvider,
      onError: (state) => state.submitError,
      onSuccess: (state) => state.passwordReset ? 'Password reset successful! You can now log in.' : null,
      onSuccessCallback: (context, state) {
        if (state.passwordReset) {
          // Navigate back to login after short delay
          Future.delayed(const Duration(seconds: 2), () {
            if (context.mounted) {
              context.go(AppRoutes.homeMap); // Or wherever your login is
            }
          });
        }
      },
    );

    final controller = ref.read(resetPasswordControllerProvider.notifier);
    final controllerState = ref.watch(resetPasswordControllerProvider);

    final formKey = useMemoized(() => GlobalKey<FormState>());
    final newPasswordController = useTextEditingController();
    final confirmPasswordController = useTextEditingController();
    final obscureNewPassword = useState(true);
    final obscureConfirmPassword = useState(true);

    // Verify code when screen loads
    useEffect(() {
      Future.microtask(() => controller.verifyCode(code));
      return null;
    }, []);

    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        iconTheme: IconThemeData(color: scheme.onPrimary),
        title: const Text(
          'Reset Password',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        titleSpacing: 0,
        centerTitle: false,
        leadingWidth: 40,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: () {
          // Show loading while verifying code
        if (controllerState.isVerifyingCode ||
            (!controllerState.codeVerified && controllerState.submitError == null)) {
          return Column(
            children: [
              const SizedBox(height: 100),
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                'Verifying reset link...',
                style: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          );
        }

        if (!controllerState.codeVerified) {
          return Column(
            children: [
              const SizedBox(height: 48),
              Icon(
                Icons.error_outline,
                size: 64,
                color: scheme.error,
              ),
              const SizedBox(height: 24),
              Text(
                'Invalid Reset Link',
                style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'This password reset link is invalid or has expired.',
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () => context.pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                ),
                child: const Text('Back to Login'),
              ),
            ],
          );
        }

          // Show form if code is verified
          return Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // --- Header ---
                Text(
                  'Create new password',
                  style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter a new password for ${controllerState.email}',
                  style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 32),

                // --- New Password ---
                Text(
                  'New Password',
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: newPasswordController,
                  obscureText: obscureNewPassword.value,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureNewPassword.value
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () =>
                          obscureNewPassword.value = !obscureNewPassword.value,
                    ),
                  ),
                  validator: Validators.validatePassword,
                  onSaved: (value) => controller.updateNewPassword(value!.trim()),
                ),
                const SizedBox(height: 20),

                // --- Confirm Password ---
                Text(
                  'Confirm Password',
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirmPassword.value,
                  textInputAction: TextInputAction.done,
                  onEditingComplete: () {
                    if (formKey.currentState?.validate() ?? false) {
                      formKey.currentState?.save();
                      controller.resetPassword();
                    }
                  },
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirmPassword.value
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () => obscureConfirmPassword.value =
                          !obscureConfirmPassword.value,
                    ),
                  ),
                  validator: (value) => Validators.validateConfirmPassword(
                    password: newPasswordController.text,
                    confirmPassword: value,
                  ),
                  onSaved: (value) => controller.updateConfirmPassword(value!.trim()),
                ),
                const SizedBox(height: 32),

                // --- Submit ---
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: controllerState.isSubmitting
                        ? null
                        : () {
                            if (formKey.currentState?.validate() ?? false) {
                              formKey.currentState?.save();
                              controller.resetPassword();
                            }
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: scheme.primary,
                      foregroundColor: scheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: controllerState.isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Reset Password',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
          );
        }(),
      ),
    );
  }
}
