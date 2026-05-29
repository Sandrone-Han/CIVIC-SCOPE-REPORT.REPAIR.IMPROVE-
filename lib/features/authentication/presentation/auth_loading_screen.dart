import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Auth loading screen shown while checking authentication state on app startup
///
/// This screen is temporary and automatically redirects based on:
/// - If authenticated → Home screen with user's role
/// - If not authenticated → Welcome screen
class AuthLoadingScreen extends StatelessWidget {
  const AuthLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // App Logo
            SvgPicture.asset(
              'assets/civic_scope_banner.svg',
              height: 100,
              colorFilter: ColorFilter.mode(scheme.primary, BlendMode.srcIn),
            ),

            const SizedBox(height: 48),

            // Loading Indicator
            CircularProgressIndicator(
              color: scheme.primary,
            ),

            const SizedBox(height: 16),

            // Loading Text
            Text(
              'Loading...',
              style: TextStyle(
                fontSize: 16,
                color: scheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}