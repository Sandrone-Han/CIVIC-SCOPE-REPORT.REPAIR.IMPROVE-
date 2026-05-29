import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/foundation.dart' show Factory;
import '../../../../core/routing/app_routes.dart';

/// This is home_guest.dart
/// Home screen shown to unauthenticated users.

class GuestHomePage extends StatefulWidget {
  const GuestHomePage({super.key});

  @override
  State<GuestHomePage> createState() => _GuestHomePageState();
}

class _GuestHomePageState extends State<GuestHomePage> {
  static const LatLng _defaultCenter = LatLng(52.4862, -1.8904);

  GoogleMapController? _mapController;

  final Set<Marker> _markers = {
    const Marker(
      markerId: MarkerId('guest_center'),
      position: _defaultCenter,
      infoWindow: InfoWindow(title: 'Birmingham'),
    ),
  };

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, //Removes back arrow
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        iconTheme: IconThemeData(color: scheme.onPrimary),
        title: SvgPicture.asset(
          'assets/civic_scope_banner.svg',
          height: 70,
          colorFilter: ColorFilter.mode(scheme.onPrimary, BlendMode.srcIn),
        ),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Map -------------------------
              const SizedBox(height: 12),
              Container(
                width: 300,
                height: 200,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: const CameraPosition(
                        target: _defaultCenter,
                        zoom: 13,
                      ),
                      onMapCreated: (controller) {
                        _mapController = controller;
                      },
                      markers: _markers,
                      myLocationButtonEnabled:
                          true, // TODO: add properly location to this map too
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                      compassEnabled: true,
                      gestureRecognizers: {
                        Factory<OneSequenceGestureRecognizer>(
                          () => EagerGestureRecognizer(),
                        ),
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              // Log In prompt ----------------------------------
              Icon(
                Icons.lock_outline,
                size: 48,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: text.headlineSmall,
                  children: [
                    const TextSpan(text: 'Please '),
                    TextSpan(
                      text: 'Log In',
                      style: TextStyle(
                        color: scheme.primary,
                        decoration: TextDecoration.underline,
                        decorationColor: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => context.push(AppRoutes.authLogIn),
                    ),
                    const TextSpan(text: ' or '),
                    TextSpan(
                      text: 'Sign Up',
                      style: TextStyle(
                        color: scheme.primary,
                        decoration: TextDecoration.underline,
                        decorationColor: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => context.push(AppRoutes.authSignUp),
                    ),
                    const TextSpan(text: '\nto be able to submit reports'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // --- Browse issues without logging in ---
              SizedBox(
                width: 280,
                child: _navCard(
                  context,
                  scheme: scheme,
                  text: text,
                  icon: Icons.location_on_outlined,
                  label: 'Browse Local Issues',
                  onTap: () => context.go(AppRoutes.searchReports),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: 280,
                child: _navCard(
                  context,
                  scheme: scheme,
                  text: text,
                  icon: Icons.location_on_outlined,
                  label: 'Local Issue 2',
                  onTap: () => context.go(AppRoutes.searchReports),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navCard(
    BuildContext context, {
    required ColorScheme scheme,
    required TextTheme text,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 280,
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: Icon(icon, color: scheme.primary),
          title: Text(
            label,
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          trailing: Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
          onTap: onTap,
        ),
      ),
    );
  }
}
