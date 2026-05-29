import 'package:flutter/material.dart';

/// This is wip_screen.dart
/// Placeholder screen for incomplete features.

///   WIPScreen()           → "This feature has not been implemented yet"
///   WIPScreen('Reports')  → "The 'Reports' feature has not been implemented yet"

class WIPScreen extends StatelessWidget {
  const WIPScreen([this.featureName]);
  final String? featureName;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final message = featureName == null
        ? 'This feature has not been implemented yet.'
        : "The '$featureName' feature has not been implemented yet.";

    return Scaffold(
      appBar: AppBar(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        iconTheme: IconThemeData(color: scheme.onPrimary),
        title: Text(
          featureName ?? 'Coming Soon',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: false,
        leadingWidth: 40,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.construction_rounded,
                size: 64,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
