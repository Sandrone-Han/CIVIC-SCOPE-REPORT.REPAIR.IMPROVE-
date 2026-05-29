import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:civic_scope/core/utils/constants/enums.dart';
import 'package:civic_scope/features/reports/data/reports_reposritory.dart';
import 'package:civic_scope/features/reports/presentation/report_detail.dart';
import 'package:civic_scope/features/reports/presentation/search_reports_screen.dart';
import 'package:civic_scope/shared/models/report_interaction_model.dart';
import 'package:civic_scope/shared/models/report_model.dart';
import 'package:civic_scope/shared/providers/auth_provider.dart';
import 'package:civic_scope/shared/widgets/empty_state_view.dart';
import '../../../core/routing/app_routes.dart';

/// This is home_citizen.dart
/// Home screen for authenticated citizen users.
/// Displays a guest sign-in prompt if accessed without authentication.

class HomeMapScreen extends ConsumerStatefulWidget {
  const HomeMapScreen({super.key});

  @override
  ConsumerState<HomeMapScreen> createState() => _HomeMapScreenState();
}

class _HomeMapScreenState extends ConsumerState<HomeMapScreen> {
  static const LatLng _defaultLocation = LatLng(52.4862, -1.8904);
  static const int _nearestIssueCount = 6;
  static const int _visibleMarkerCount = 30;

  final _reportsRepository = ReportsRepository();

  GoogleMapController? _mapController;
  LatLng _mapCenter = _defaultLocation;
  LatLng _latestCameraCenter = _defaultLocation;
  Set<Marker> _markers = const <Marker>{};
  List<_IssueDistance> _nearestIssues = const <_IssueDistance>[];

  bool _isLoading = true;
  bool _isResolvingLocation = false;
  bool _hasLocationPermission = false;
  String? _errorMessage;

  List<_IssueItem> _allIssues = const <_IssueItem>[];

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initializeScreen() async {
    await _resolveInitialMapCenter();
    await _loadIssues();
  }

  Future<void> _resolveInitialMapCenter() async {
    final hasPermission = await _ensureLocationPermission(
      requestIfNeeded: true,
    );
    if (!hasPermission) {
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition();
      _mapCenter = LatLng(position.latitude, position.longitude);
      _latestCameraCenter = _mapCenter;
      _hasLocationPermission = true;
    } catch (_) {
      // Keep default map center if current location cannot be read.
    }
  }

  Future<void> _loadIssues() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final reportsFuture = _reportsRepository.getReports();
      final interactionsFuture = _reportsRepository.getInteractionsByReportId();

      final reports = await reportsFuture;
      final interactions = await interactionsFuture;

      _allIssues = reports
          .map(
            (report) => _IssueItem(
              report: report,
              interaction: interactions[report.id],
            ),
          )
          .toList();

      _recomputeNearbyIssues(center: _mapCenter, shouldUpdateState: false);

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      await _moveCameraTo(_mapCenter);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load nearby issues. Pull down to retry.';
      });
    }
  }

  Future<void> _moveToCurrentLocation() async {
    if (_isResolvingLocation) return;

    setState(() {
      _isResolvingLocation = true;
    });

    try {
      final hasPermission = await _ensureLocationPermission(
        requestIfNeeded: true,
      );
      if (!hasPermission) return;

      final position = await Geolocator.getCurrentPosition();
      final currentLatLng = LatLng(position.latitude, position.longitude);

      if (!mounted) return;
      setState(() {
        _hasLocationPermission = true;
        _mapCenter = currentLatLng;
        _latestCameraCenter = currentLatLng;
      });

      _recomputeNearbyIssues(center: currentLatLng);
      await _moveCameraTo(currentLatLng);
    } catch (e) {
      _showMessage('Could not get your location: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isResolvingLocation = false;
        });
      }
    }
  }

  Future<void> _moveCameraTo(LatLng target) async {
    await _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(target: target, zoom: 15)),
    );
  }

  Future<bool> _ensureLocationPermission({
    required bool requestIfNeeded,
  }) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showMessage('Location service is disabled.');
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied && requestIfNeeded) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      _showMessage(
        'Location permission is permanently denied. Enable it from app settings.',
      );
      return false;
    }

    return true;
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _recomputeNearbyIssues({
    required LatLng center,
    bool shouldUpdateState = true,
  }) {
    final withDistance =
        _allIssues
            .map(
              (issue) => _IssueDistance(
                issue: issue,
                distanceMeters: Geolocator.distanceBetween(
                  center.latitude,
                  center.longitude,
                  issue.report.lati,
                  issue.report.long,
                ),
              ),
            )
            .toList()
          ..sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));

    final nearestIssues = withDistance.take(_nearestIssueCount).toList();
    final markers = withDistance.take(_visibleMarkerCount).map((issueDistance) {
      final report = issueDistance.issue.report;
      return Marker(
        markerId: MarkerId(report.id),
        position: LatLng(report.lati, report.long),
        infoWindow: InfoWindow(title: report.title),
        onTap: () => _openIssueDetail(issueDistance.issue),
      );
    }).toSet();

    if (!shouldUpdateState) {
      _nearestIssues = nearestIssues;
      _markers = markers;
      return;
    }

    if (!mounted) return;
    setState(() {
      _nearestIssues = nearestIssues;
      _markers = markers;
    });
  }

  void _openIssueDetail(_IssueItem issue) {
    final interaction = issue.interaction;
    final report = issue.report;

    final reportType = ReportType.values.firstWhere(
      (value) => value.name == report.category,
      orElse: () => ReportType.other,
    );

    final civicReport = CivicReport(
      id: report.id,
      title: report.title,
      description: report.description,
      type: reportType,
      author: report.author,
      latitude: report.lati,
      longitude: report.long,
      dateCreated: report.created,
      status: interaction?.reportStatus ?? ReportStatus.reported,
      upvotes: interaction?.upvotes ?? 0,
      comments: interaction?.comments ?? const <Comment>[],
      imagePath: report.evidenceURL,
    );

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ReportDetailPage(report: civicReport)),
    );
  }

  String _distanceLabel(double distanceMeters) {
    if (distanceMeters < 1000) {
      return '${distanceMeters.round()} m away';
    }
    return '${(distanceMeters / 1000).toStringAsFixed(1)} km away';
  }

  String _statusLabel(ReportStatus status) => switch (status) {
    ReportStatus.reported => 'Reported',
    ReportStatus.assigned => 'Assigned',
    ReportStatus.underReview => 'Under Review',
    ReportStatus.underWork => 'Under Work',
    ReportStatus.repaired => 'Repaired',
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final authState = ref.watch(authStateProvider);
    final isAuthenticated = authState == AppAuthState.authenticated;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        iconTheme: IconThemeData(color: scheme.onPrimary),
        title: SvgPicture.asset(
          'assets/civic_scope_banner.svg',
          height: 75,
          colorFilter: ColorFilter.mode(scheme.onPrimary, BlendMode.srcIn),
        ),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          if (isAuthenticated)
            IconButton(
              icon: Icon(Icons.notifications_outlined, color: scheme.onPrimary),
              onPressed: () {
                context.push(AppRoutes.notifications);
              },
            ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          double mapHeight = constraints.maxHeight * 0.7;

          if (!isAuthenticated) mapHeight = constraints.maxHeight * 0.5;

          return Column(
            children: [
              SizedBox(
                height: mapHeight,
                width: double.infinity,
                child: Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _mapCenter,
                        zoom: 15,
                      ),
                      onMapCreated: (controller) async {
                        _mapController = controller;
                        await _moveCameraTo(_mapCenter);
                      },
                      onCameraMove: (position) {
                        _latestCameraCenter = position.target;
                      },
                      onCameraIdle: () {
                        _recomputeNearbyIssues(center: _latestCameraCenter);
                      },
                      markers: _markers,
                      myLocationButtonEnabled: false,
                      myLocationEnabled: _hasLocationPermission,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                      compassEnabled: true,
                    ),
                    if (_isLoading)
                      Container(
                        color: Colors.black.withValues(alpha: 0.18),
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                    Positioned(
                      right: 16,
                      top: 16,
                      child: Material(
                        color: scheme.surface,
                        elevation: 2,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: _moveToCurrentLocation,
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: _isResolvingLocation
                                ? SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: scheme.primary,
                                    ),
                                  )
                                : Icon(
                                    Icons.my_location,
                                    color: scheme.primary,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _buildIssuesList(context, scheme, text, isAuthenticated),
            ],
          );
        },
      ),
    );
  }

  Widget _buildIssuesList(
    BuildContext context,
    ColorScheme scheme,
    TextTheme text,
    bool isAuthenticated,
  ) {
    return Expanded(
      child: RefreshIndicator(
        onRefresh: _loadIssues,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          children: [
            if (!isAuthenticated) ...{
              // Heading
              Text(
                'Unlock Full Access',
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 12),

              // Subtext
              Text(
                'Sign in to report issues, vote on problems and comment.',
                style: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 32),

              // Sign In button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: () => context.push(AppRoutes.authLogIn),
                  icon: const Icon(Icons.login),
                  label: const Text('Sign In'),
                ),
              ),

              SizedBox(height: 12),

              // Sign Up button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => context.push(AppRoutes.authSignUp),
                  icon: const Icon(Icons.person_add_outlined),
                  label: const Text('Create Account'),
                ),
              ),
            },

            Row(
              children: [
                Expanded(
                  child: Text(
                    'Closest Issues',
                    style: text.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => context.go(AppRoutes.searchReports),
                  child: const Text('See all'),
                ),
              ],
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  _errorMessage!,
                  style: text.bodyMedium?.copyWith(color: scheme.error),
                ),
              ),
            if (!_isLoading && _nearestIssues.isEmpty)
              Card(
                margin: EdgeInsets.zero,
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: EmptyStateView(
                    icon: Icons.location_searching_outlined,
                    message: 'No issues found near this area yet.',
                    iconSize: 44,
                  ),
                ),
              ),
            ..._nearestIssues.map(
              (issueDistance) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _issueCard(
                  scheme: scheme,
                  text: text,
                  issueDistance: issueDistance,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _issueCard({
    required ColorScheme scheme,
    required TextTheme text,
    required _IssueDistance issueDistance,
  }) {
    final report = issueDistance.issue.report;
    final status =
        issueDistance.issue.interaction?.reportStatus ?? ReportStatus.reported;

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(Icons.location_on_outlined, color: scheme.primary),
        title: Text(
          report.title,
          style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${_distanceLabel(issueDistance.distanceMeters)} · ${_statusLabel(status)}',
        ),
        trailing: Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
        onTap: () => _openIssueDetail(issueDistance.issue),
      ),
    );
  }
}

class _IssueItem {
  const _IssueItem({required this.report, required this.interaction});

  final Report report;
  final ReportInteraction? interaction;
}

class _IssueDistance {
  const _IssueDistance({required this.issue, required this.distanceMeters});

  final _IssueItem issue;
  final double distanceMeters;
}
