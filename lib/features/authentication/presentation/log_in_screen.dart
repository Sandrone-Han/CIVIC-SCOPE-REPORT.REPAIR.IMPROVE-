import 'package:civic_scope/features/authentication/controllers/log_in_controller.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:civic_scope/core/utils/validators/validators.dart';
import 'package:civic_scope/core/hooks/use_state_listener.dart';
import 'package:civic_scope/core/routing/app_routes.dart';

/// This is login.dart
/// Login screen using hooks for state management

class LoginPage extends HookConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useStateListener(
      ref: ref,
      provider: logInControllerProvider,
      onError: (state) => state.submitError,
      onSuccess: (state) => state.submitSuccess ? 'Logged in successfully!' : null,
    );

    final controller = ref.read(logInControllerProvider.notifier);

    final formKey = useMemoized(() => GlobalKey<FormState>());
    final emailController = useTextEditingController();
    final emailKey = useMemoized(() => GlobalKey<FormFieldState<String>>());
    final passwordController = useTextEditingController();
    final obscurePassword = useState(true);

    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        iconTheme: IconThemeData(color: scheme.onPrimary),
        title: const Text(
          'Log In',
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
              // --- Header ---
              Text(
                'Welcome back',
                style: text.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Sign in to continue',
                style: text.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              // --- Email ---
              Text(
                'Email',
                style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: emailKey,
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'you@example.com',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: Validators.validateEmail,
                onChanged: (value) {
                  controller.updateEmail(value.trim());
                  emailKey.currentState?.validate();
                },
                onSaved: (value) => controller.updateEmail(value!.trim()),
              ),
              const SizedBox(height: 20),

              // --- Password ---
              Text(
                'Password',
                style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: passwordController,
                obscureText: obscurePassword.value,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword.value
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () =>
                        obscurePassword.value = !obscurePassword.value,
                  ),
                ),
                validator: Validators.validatePassword,
                onChanged: (value) => controller.updatePassword(value.trim()),
                onSaved: (value) => controller.updatePassword(value!.trim()),
              ),
              const SizedBox(height: 8),

              // --- Forgot password ---
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    context.push(AppRoutes.authForgotPassword, extra: {
                      'email': emailController.text.trim(),
                    });
                  },
                  child: const Text('Forgot password?'),
                ),
              ),
              const SizedBox(height: 24),

              // --- Submit ---
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      formKey.currentState?.save();
                      controller.submit();
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
                  child: const Text(
                    'Log In',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // --- Register ---
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account?", style: text.bodyMedium),
                  TextButton(
                    onPressed: () => context.push(AppRoutes.authSignUp, extra: {
                        'email': emailController.text.trim(),
                        'password': passwordController.text,
                      }),
                    child: const Text('Sign up'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
