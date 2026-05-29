import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Listen to state changes and show error/success messages
void useStateListener<T>({
  required WidgetRef ref,
  required NotifierProvider<Notifier<T>, T> provider,
  String? Function(T)? onError,
  String? Function(T)? onSuccess,
  void Function(BuildContext, T)? onSuccessCallback,
}) {
  final context = useContext();

  void showSnackBar(String message, Color backgroundColor) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger == null) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: backgroundColor,
          ),
        );
    });
  }

  // Listen for errors
  if (onError != null) {
    ref.listen<T>(
      provider,
      (previous, next) {
        final errorMessage = onError(next);
        if (errorMessage != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
    );
  }

  // Listen for success
  if (onSuccess != null || onSuccessCallback != null) {
    ref.listen<T>(
      provider,
      (previous, next) {
        if (onSuccess != null) {
          final successMessage = onSuccess(next);
          if (successMessage != null && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(successMessage),
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
            );
          }
        }

        if (onSuccessCallback != null && context.mounted) {
          onSuccessCallback(context, next);
        }
      },
    );
  }
}
