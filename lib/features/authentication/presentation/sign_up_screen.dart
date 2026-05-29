import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:civic_scope/core/utils/validators/validators.dart';
import 'package:civic_scope/core/hooks/use_state_listener.dart';
import '../controllers/sign_up_controller.dart';

/// This is sign_up.dart
/// Registration screen using hooks for state management

class SignUpScreen extends HookConsumerWidget {
  const SignUpScreen({
    super.key,
    this.initialEmail = '',
    this.initialPassword = '',
  });

  final String initialEmail;
  final String initialPassword;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useStateListener(
      ref: ref,
      provider: signUpControllerProvider,
      onError: (state) => state.submitError,
      onSuccess: (state) => state.submitSuccess ? 'Account created successfully!' : null,
    );

    final controller = ref.read(signUpControllerProvider.notifier);
    final isSubmitting = ref.watch(
      signUpControllerProvider.select((state) => state.isSubmitting),
    );

    // Form controllers for text fields
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final nameController = useTextEditingController();
    final emailController = useTextEditingController(text: initialEmail);
    final passwordController = useTextEditingController(text: initialPassword);
    final confirmPasswordController = useTextEditingController();

    // Focus nodes for keyboard navigation
    final emailFocusNode = useFocusNode();
    final passwordFocusNode = useFocusNode();
    final confirmPasswordFocusNode = useFocusNode();

    final obscurePassword = useState(true);

    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        iconTheme: IconThemeData(color: scheme.onPrimary),
        title: const Text(
          'Sign Up',
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
                'Hello, Welcome',
                style: text.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Sign up to continue',
                style: text.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              // --- Full name ---
              Text(
                'Full Name',
                style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: nameController,
                keyboardType: TextInputType.name,
                textInputAction: TextInputAction.next,
                onEditingComplete: () => emailFocusNode.requestFocus(),
                decoration: const InputDecoration(
                  hintText: 'Jane Smith',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              // --- Email ---
              Text(
                'Email',
                style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: emailController,
                focusNode: emailFocusNode,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onEditingComplete: () => passwordFocusNode.requestFocus(),
                decoration: const InputDecoration(
                  hintText: 'you@example.com',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: Validators.validateEmail,
                onSaved: (value) => controller.updateEmail(value!.trim()),
              ),
              const SizedBox(height: 10),

              // --- Password ---
              Text(
                'Password',
                style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: passwordController,
                focusNode: passwordFocusNode,
                obscureText: obscurePassword.value,
                textInputAction: TextInputAction.next,
                onEditingComplete: () => confirmPasswordFocusNode.requestFocus(),
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
                onSaved: (value) => controller.updatePassword(value!.trim()),
              ),
              const SizedBox(height: 10),

              // --- Confirm password ---
              Text(
                'Confirm Password',
                style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: confirmPasswordController,
                focusNode: confirmPasswordFocusNode,
                obscureText: obscurePassword.value,
                textInputAction: TextInputAction.done,
                onEditingComplete: () {
                  if (formKey.currentState?.validate() ?? false) {
                    formKey.currentState?.save();
                    controller.signUp();
                  }
                },
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
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (v != passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
                onSaved: (value) => controller.updateConfirmPassword(value!.trim()),
              ),
              const SizedBox(height: 32),

              // --- Submit ---
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      formKey.currentState?.save();
                      controller.signUp();
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
                          'Create Account',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
              const SizedBox(height: 8),

              // --- Back to login ---
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Already have an account?', style: text.bodyMedium),
                  TextButton(
                    onPressed: () {
                      FocusScope.of(context).unfocus();
                      context.pop();
                    },
                    child: const Text('Log in'),
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
