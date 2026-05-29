import 'package:civic_scope/features/authentication/domain/user_model.dart';
import 'package:civic_scope/features/authentication/repositories/user_repository.dart';
import 'package:civic_scope/shared/models/report_interaction_model.dart';
import 'package:civic_scope/shared/providers/auth_provider.dart';
import 'package:civic_scope/features/roles/admin/data/deletion_requests/deletion_requests_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../data/reports_reposritory.dart';
import 'search_reports_screen.dart';
import 'package:civic_scope/core/utils/constants/enums.dart';

/// This is report_detail.dart
/// The dedicated issue page — like a GitHub issue view
/// Shows full report info such as upvotes, comments, and fund raising
/// All data is passed in via CivicReport from reports_list.dart (no hardcoded dummy data here)

class ReportDetailPage extends ConsumerStatefulWidget {
  const ReportDetailPage({super.key, required this.report});
  final CivicReport report;

  @override
  ConsumerState<ReportDetailPage> createState() => _ReportDetailPageState();
}

// --- State ---

class _ReportDetailPageState extends ConsumerState<ReportDetailPage> {
  final _reportsRepository = ReportsRepository();
  final _deletionRequestsRepository = DeletionRequestsRepository();

  late int _upvotes;
  late List<Comment> _comments;
  late double _raisedAmount;
  bool _hasUpvoted = false;
  final _commentController = TextEditingController();
  late String _username = "";

  GoogleMapController? _previewMapController;

  @override
  void initState() {
    super.initState();
    _upvotes = widget.report.upvotes;
    _comments = List.from(widget.report.comments);
    _raisedAmount = widget.report.raisedAmount;
    _getUsername(widget.report);
  }

  @override
  void dispose() {
    _previewMapController?.dispose();
    _commentController.dispose();
    super.dispose();
  }

  // --- Label Helpers ---

  String _typeLabel(ReportType t) => switch (t) {
    ReportType.pothole => 'Pothole',
    ReportType.rubbish => 'Rubbish',
    ReportType.other => 'Other',
  };

  String _statusLabel(ReportStatus s) => switch (s) {
    ReportStatus.reported => 'Reported',
    ReportStatus.assigned => 'Assigned',
    ReportStatus.underReview => 'Under Review',
    ReportStatus.underWork => 'Under Work',
    ReportStatus.repaired => 'Repaired',
  };

  Color _statusColor(ReportStatus s, ColorScheme cs) => switch (s) {
    ReportStatus.reported => cs.error,
    ReportStatus.assigned => cs.primary,
    ReportStatus.underReview => cs.secondary,
    ReportStatus.underWork => Colors.orange,
    ReportStatus.repaired => Colors.green,
  };

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  Future<void> _showAuthPrompt() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Want to do more?'),
          content: const Text(
            'Quickly login or register. Go to settings to authenticate.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // --- Actions ---

  Future<void> _toggleUpvote(bool isAuthenticated) async {
    if (!isAuthenticated) {
      await _showAuthPrompt();
      return;
    }

    final report = widget.report;

    try {
      await _reportsRepository.incrementUpvote(
        reportId: report.id,
        increase: !_hasUpvoted,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update upvote right now.')),
      );
      return;
    }

    setState(() {
      _hasUpvoted ? _upvotes-- : _upvotes++;
      _hasUpvoted = !_hasUpvoted;
    });
  }

  void _getUsername(CivicReport report) async {
    final user = await UserRepository().getUserById(report.author);

    setState(() {
      _username = user!.displayName;
    });
  }

  Future<void> _submitComment(bool isAuthenticated) async {
    if (!isAuthenticated) {
      await _showAuthPrompt();
      return;
    }

    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) {
      await _showAuthPrompt();
      return;
    }

    final text = _commentController.text.trim();
    final report = widget.report;

    if (text.isEmpty) return;

    final comment = Comment(currentUserId, text);

    try {
      await _reportsRepository.addComment(
        reportId: report.id,
        comment: comment,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not post comment right now.')),
      );
      return;
    }

    if (!mounted) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _comments.add(Comment("You", text));
      _commentController.clear();
    });
  }

  void _contributeFunds() {
    setState(() => _raisedAmount += 10.0);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('£10 contributed — thank you!'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Future<void> _openDeletionRequestDialog(String requesterId) async {
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _DeletionRequestSheet(
        reportId: widget.report.id,
        onSubmit: (reasons) async {
          await _deletionRequestsRepository.createOrUpdateDeletionRequest(
            reportId: widget.report.id,
            requesterId: requesterId,
            reasons: reasons,
          );
        },
      ),
    );

    if (!mounted || submitted != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Deletion request submitted for review.')),
    );
  }

  // --- Build ---

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final report = widget.report;
    final reportLatLng = LatLng(report.latitude, report.longitude);
    final fundProgress = report.fundGoal != null
        ? (_raisedAmount / report.fundGoal!).clamp(0.0, 1.0)
        : 1.0;
    final isAuthenticated =
        ref.watch(authStateProvider) == AppAuthState.authenticated;
    final currentUserId = ref.watch(currentUserIdProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        iconTheme: IconThemeData(color: scheme.onPrimary),
        title: Text(
          report.title,
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        titleSpacing: 0,
        centerTitle: false,
        leadingWidth: 40,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          if (isAuthenticated)
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value != 'request_deletion') return;

                if (currentUserId == null) {
                  await _showAuthPrompt();
                  return;
                }

                await _openDeletionRequestDialog(currentUserId);
              },
              itemBuilder: (_) => const [
                PopupMenuItem<String>(
                  value: 'request_deletion',
                  child: Text('Request Deletion'),
                ),
              ],
            ),
        ],
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          // --- Title and Metadata ---
          Text(
            report.title,
            style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Reported by $_username · ${_formatDate(report.dateCreated)}', //TODO: FIX HERE
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _chip(
                _statusLabel(report.status),
                _statusColor(report.status, scheme),
                scheme,
              ),
              const SizedBox(width: 6),
              _chip(_typeLabel(report.type), scheme.secondaryContainer, scheme),
            ],
          ),
          const SizedBox(height: 20),

          // --- Description ---
          _sectionTitle('Description', scheme, text),
          const SizedBox(height: 8),
          Text(
            report.description,
            style: text.bodyMedium?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 20),

          // --- Evidence Image ---
          _sectionTitle('Evidence', scheme, text),
          const SizedBox(height: 8),

          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                report.imagePath!.trim(),
                fit: BoxFit.cover,
                errorBuilder: (_, error, stackTrace) {
                  return Container(
                    color: scheme.surfaceContainerLow,
                    alignment: Alignment.center,
                    child: Text(
                      'Could not load evidence image',
                      style: text.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 20),

          // --- Location ---
          _sectionTitle('Location', scheme, text),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 16, color: scheme.primary),
              const SizedBox(width: 4),
              Text(
                '${report.latitude.toStringAsFixed(5)}, ${report.longitude.toStringAsFixed(5)}',
                style: text.bodySmall?.copyWith(color: scheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scheme.outlineVariant),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: reportLatLng,
                    zoom: 16,
                  ),
                  onMapCreated: (controller) {
                    _previewMapController = controller;
                  },
                  markers: {
                    Marker(
                      markerId: MarkerId(report.id),
                      position: reportLatLng,
                      infoWindow: InfoWindow(title: report.title),
                    ),
                  },
                  zoomControlsEnabled: false,
                  myLocationButtonEnabled: false,
                  mapToolbarEnabled: false,
                  compassEnabled: false,
                  rotateGesturesEnabled: false,
                  tiltGesturesEnabled: false,
                ),
                Positioned(
                  right: 10,
                  top: 10,
                  child: Material(
                    color: scheme.surface,
                    elevation: 2,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () async {
                        await _previewMapController?.animateCamera(
                          CameraUpdate.newLatLngZoom(reportLatLng, 16),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Icon(
                          Icons.my_location,
                          size: 18,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // TODO: embed GoogleMap preview — see citizen_report.dart for map implementation reference
          /*Container(
              height: 180,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.map_outlined, color: scheme.onSurfaceVariant),
                    const SizedBox(height: 4),
                    Text(
                      'Map preview coming soon',
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),*/

          // --- Upvote ---
          _sectionTitle('Support this Report', scheme, text),
          const SizedBox(height: 8),
          Row(
            children: [
              FilledButton.icon(
                onPressed: () => _toggleUpvote(isAuthenticated),
                style: FilledButton.styleFrom(
                  backgroundColor: _hasUpvoted
                      ? scheme.primary
                      : scheme.surfaceContainerLow,
                  foregroundColor: _hasUpvoted
                      ? scheme.onPrimary
                      : scheme.onSurface,
                ),
                icon: Icon(
                  _hasUpvoted ? Icons.thumb_up : Icons.thumb_up_outlined,
                  size: 18,
                ),
                label: Text('$_upvotes Upvotes'),
              ),
              if (!isAuthenticated) ...[
                const SizedBox(width: 10),
                Text(
                  'Log in to react',
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          // --- Raise Funds ---
          _sectionTitle('Raise Funds', scheme, text),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '£${_raisedAmount.toStringAsFixed(0)} raised',
                        style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (report.fundGoal != null)
                        Text(
                          'Goal: £${report.fundGoal!.toStringAsFixed(0)}',
                          style: text.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: fundProgress,
                      minHeight: 10,
                      backgroundColor: scheme.surfaceContainerLow,
                      valueColor: AlwaysStoppedAnimation(scheme.primary),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (report.fundGoal != null) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _contributeFunds,
                        icon: const Icon(Icons.volunteer_activism_outlined),
                        label: const Text('Contribute £10'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // --- Comments ---
          _sectionTitle('Comments (${_comments.length})', scheme, text),
          const SizedBox(height: 8),
          ..._comments.map(
            (c) => _CommentTile(
              author: c.commentAuthor,
              text: c.comment,
              scheme: scheme,
              textTheme: text,
            ),
          ),
          const SizedBox(height: 12),

          // --- Add Comment Input ---
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  minLines: 1,
                  maxLines: 3,
                  readOnly: !isAuthenticated,
                  onTap: isAuthenticated ? null : _showAuthPrompt,
                  decoration: InputDecoration(
                    hintText: isAuthenticated
                        ? 'Add a comment...'
                        : 'Log in to add a comment',
                    filled: true,
                    fillColor: scheme.surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => _submitComment(isAuthenticated),
                style: FilledButton.styleFrom(
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
                  padding: const EdgeInsets.all(14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Icon(Icons.send),
              ),
            ],
          ),
          if (!isAuthenticated) ...[
            const SizedBox(height: 8),
            Text(
              'Want to do more? Quickly login or register.',
              style: text.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _sectionTitle(String title, ColorScheme scheme, TextTheme text) {
    return Text(
      title,
      style: text.titleMedium?.copyWith(
        fontWeight: FontWeight.w800,
        color: scheme.primary,
      ),
    );
  }

  Widget _chip(String label, Color bg, ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: bg.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: bg == scheme.secondaryContainer
              ? scheme.onSecondaryContainer
              : bg,
        ),
      ),
    );
  }
}

// --- Comment Tile Widget ---

class _CommentTile extends StatefulWidget {
  const _CommentTile({
    required this.author,
    required this.text,
    required this.scheme,
    required this.textTheme,
  });
  final String author;
  final String text;
  final ColorScheme scheme;
  final TextTheme textTheme;

  @override
  State<_CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<_CommentTile> {
  AppUser? _user;

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  Future<void> _fetchUser() async {
    final user = await UserRepository().getUserById(widget.author);
    if (mounted) setState(() => _user = user);
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _user?.displayName ?? widget.author;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: widget.scheme.primaryContainer,
            child: Text(
              displayName[0],
              style: TextStyle(
                color: widget.scheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: widget.scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: widget.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(widget.text, style: widget.textTheme.bodyMedium),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeletionRequestSheet extends StatefulWidget {
  const _DeletionRequestSheet({required this.reportId, required this.onSubmit});

  final String reportId;
  final Future<void> Function(List<String> reasons) onSubmit;

  @override
  State<_DeletionRequestSheet> createState() => _DeletionRequestSheetState();
}

class _DeletionRequestSheetState extends State<_DeletionRequestSheet> {
  final _reasonController = TextEditingController();
  final List<String> _reasons = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _addReason() {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) return;

    setState(() {
      _reasons.add(reason);
      _reasonController.clear();
    });
  }

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);

    if (_reasons.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please add at least one reason.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await widget.onSubmit(_reasons);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Could not submit deletion request right now.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final maxSheetHeight = MediaQuery.of(context).size.height * 0.85;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxSheetHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Request Report Deletion',
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text('Report ID: ${widget.reportId}', style: text.bodySmall),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _reasonController,
                        minLines: 2,
                        maxLines: 4,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'Reason',
                          hintText:
                              'Describe why this report should be deleted.',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: _isSubmitting ? null : _addReason,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Reason'),
                        ),
                      ),
                      if (_reasons.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Reasons Added (${_reasons.length})',
                          style: text.labelLarge,
                        ),
                        const SizedBox(height: 6),
                        ...List.generate(_reasons.length, (index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 3),
                                  child: Icon(Icons.circle, size: 7),
                                ),
                                const SizedBox(width: 8),
                                Expanded(child: Text(_reasons[index])),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  onPressed: _isSubmitting
                                      ? null
                                      : () {
                                          setState(() {
                                            _reasons.removeAt(index);
                                          });
                                        },
                                  icon: const Icon(Icons.close),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_outlined),
                  label: const Text('Submit Deletion Request'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
