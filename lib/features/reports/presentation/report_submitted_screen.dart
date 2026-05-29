import 'package:civic_scope/shared/providers/shared_preferences_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routing/app_routes.dart';

class ReportSubmittedScreen extends ConsumerStatefulWidget {
  const ReportSubmittedScreen({
    super.key,
    required this.reportCategory,
    required this.reportStatus,
  });

  final String reportCategory;
  final String reportStatus;

  @override
  ConsumerState<ReportSubmittedScreen> createState() =>
      _ReportSubmittedScreenState();
}

class _ReportSubmittedScreenState extends ConsumerState<ReportSubmittedScreen> {
  @override
  void initState() {
    super.initState();
    _markSubmitted();
  }

  Future<void> _markSubmitted() async {
    final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString('last_screen', 'report_submitted');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final titleColor = scheme.onSurface;
    final subtitleColor = scheme.onSurfaceVariant;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        automaticallyImplyLeading: false,
        title: const Text(
          'Report Submitted',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: false,
        leadingWidth: 40,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 32,
                ),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: scheme.outlineVariant),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.shadow.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 62,
                      backgroundColor: scheme.primaryContainer,
                      child: Icon(
                        Icons.check_rounded,
                        size: 78,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Thank You!',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Divider(color: scheme.outlineVariant),
                    const SizedBox(height: 12),
                    Text(
                      'Your report has been submitted',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: subtitleColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Category: ${widget.reportCategory}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: titleColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Status: ${widget.reportStatus}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'We will notify you with updates',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: subtitleColor,
                      ),
                    ),
                    const SizedBox(height: 30),
                    FilledButton(
                      onPressed: () => context.go(AppRoutes.homeMap),
                      child: const Text('Go to Home'),
                    ),
                    const SizedBox(height: 30),
                    OutlinedButton(
                      onPressed: () => context.pop(),
                      child: const Text('Make New Report'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
