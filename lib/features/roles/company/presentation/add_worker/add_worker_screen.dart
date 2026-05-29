import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:civic_scope/features/roles/company/data/company_repository.dart';
import 'package:civic_scope/shared/providers/auth_provider.dart';
import 'package:civic_scope/shared/providers/user_provider.dart';
import 'package:civic_scope/core/utils/constants/enums.dart';
import 'package:civic_scope/shared/widgets/empty_state_view.dart';

class AddWorkerScreen extends ConsumerStatefulWidget {
  // 注意：这里去掉了 const 构造函数，以防万一
  const AddWorkerScreen({super.key});

  @override
  ConsumerState<AddWorkerScreen> createState() => _AddWorkerScreenState();
}

class _AddWorkerScreenState extends ConsumerState<AddWorkerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repository = CompanyRepository();
  String _email = '';
  bool _needsColorBlindUI = false;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isAuthenticated =
        ref.watch(authStateProvider) == AppAuthState.authenticated;
    final companyId = ref.watch(currentUserCompanyIdProvider);

    if (!isAuthenticated) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          iconTheme: IconThemeData(color: scheme.onPrimary),
          title: const Text(
            'Register New Worker',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          titleSpacing: 0,
          centerTitle: false,
          leadingWidth: 40,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        body: const EmptyStateView(
          icon: Icons.lock_outline,
          message: 'Please log in to register workers.',
        ),
      );
    }

    if (companyId == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          iconTheme: IconThemeData(color: scheme.onPrimary),
          title: const Text(
            'Register New Worker',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          titleSpacing: 0,
          centerTitle: false,
          leadingWidth: 40,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        body: const EmptyStateView(
          icon: Icons.business_outlined,
          message: 'Your account is not linked to a company yet.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        iconTheme: IconThemeData(color: scheme.onPrimary),
        title: const Text(
          'Register New Worker',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        titleSpacing: 0,
        centerTitle: false,
        leadingWidth: 40,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  final email = (value ?? '').trim();
                  if (email.isEmpty) return 'Please enter worker email';
                  if (!email.contains('@') || !email.contains('.')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
                onSaved: (value) => _email = value ?? '',
              ),
              const SizedBox(height: 24),
              SwitchListTile(
                title: const Text('Color-Blind Friendly UI'),
                value: _needsColorBlindUI,
                onChanged: (bool value) {
                  FocusScope.of(context).unfocus();
                  setState(() => _needsColorBlindUI = value);
                },
              ),
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: _isSubmitting
                    ? null
                    : () async {
                      final messenger = ScaffoldMessenger.of(context);
                        FocusScope.of(context).unfocus();
                        final isValid = _formKey.currentState?.validate() ?? false;
                        if (!isValid) return;
                        _formKey.currentState?.save();

                        setState(() => _isSubmitting = true);

                        try {
                          await _repository.addWorkerToCompany(
                            _email.trim(),
                            companyId,
                          );

                          if (!context.mounted) return;
                          context.pop();
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Worker ${_email.trim()} added to company.'),
                            ),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          setState(() => _isSubmitting = false);
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Could not add worker: $e'),
                            ),
                          );
                        }
                      },
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Confirm Registration'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
