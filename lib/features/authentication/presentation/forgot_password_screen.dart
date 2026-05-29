import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:civic_scope/core/utils/validators/validators.dart';
import 'package:civic_scope/core/hooks/use_state_listener.dart';
import '../controllers/forgot_password_controller.dart';

/// Forgot Password Screen - sends password reset email
class ForgotPasswordScreen extends HookConsumerWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail = ''});
  final String initialEmail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useStateListener(
      ref: ref,
      provider: forgotPasswordControllerProvider,
      onError: (state) => state.submitError,
      onSuccess: (state) => state.emailSent ? 'Reset link sent! Check your email.' : null,
    );

    final controller = ref.read(forgotPasswordControllerProvider.notifier);
    final isSubmitting = ref.watch(
      forgotPasswordControllerProvider.select((state) => state.isSubmitting),
    );
    final emailSent = ref.watch(
      forgotPasswordControllerProvider.select((state) => state.emailSent),
    );

    final formKey = useMemoized(() => GlobalKey<FormState>());
    final emailController = useTextEditingController(text: initialEmail);

    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        iconTheme: IconThemeData(color: scheme.onPrimary),
        title: const Text(
          'Forgot Password',
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
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // --- Header ---
              Text(
                'Reset your password',
                style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your email and we\'ll send you a link to reset your password.',
                style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 32),

              // --- Email ---
              Text(
                'Email',
                style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                onEditingComplete: () {
                  if (formKey.currentState?.validate() ?? false) {
                    formKey.currentState?.save();
                    controller.sendEmail();
                  }
                },
                decoration: const InputDecoration(
                  hintText: 'you@example.com',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: Validators.validateEmail,
                onSaved: (value) => controller.updateEmail(value!.trim()),
              ),
              const SizedBox(height: 32),

              // --- Submit ---
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: isSubmitting
                      ? null
                      : () {
                          if (formKey.currentState?.validate() ?? false) {
                            formKey.currentState?.save();
                            controller.sendEmail();
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
                  child: isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Send Reset Link',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                ),
              ),

              // --- Info Box ---
              if (emailSent) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: scheme.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: scheme.primary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Click the link in the email to reset your password.',
                          style: text.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // --- Back to login ---
              Center(
                child: TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('Back to Log In'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
