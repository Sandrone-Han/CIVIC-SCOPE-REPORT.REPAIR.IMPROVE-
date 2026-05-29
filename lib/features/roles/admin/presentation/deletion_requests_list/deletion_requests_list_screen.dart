import 'package:civic_scope/features/roles/admin/data/deletion_requests/deletion_requests_repository.dart';
import 'package:civic_scope/features/roles/admin/domain/deletion_requests/deletion_request.dart';
import 'package:civic_scope/features/reports/data/reports_reposritory.dart';
import 'package:civic_scope/core/utils/constants/enums.dart';
import 'package:civic_scope/shared/models/report_interaction_model.dart';
import 'package:civic_scope/shared/models/report_model.dart';
import 'package:flutter/material.dart';

String _formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

class DeletionRequestsListScreen extends StatefulWidget {
  DeletionRequestsListScreen({
    super.key,
    DeletionRequestsRepository? repository,
    ReportsRepository? reportsRepository,
  })  : repository = repository ?? DeletionRequestsRepository(),
        reportsRepository = reportsRepository ?? ReportsRepository();

  final DeletionRequestsRepository repository;
  final ReportsRepository reportsRepository;

  @override
  State<DeletionRequestsListScreen> createState() =>
      _DeletionRequestsListScreenState();
}

class _DeletionRequestsListScreenState
    extends State<DeletionRequestsListScreen> {
  //final _repository = DeletionRequestsRepository();
  //final _reportsRepository = ReportsRepository();
  late final DeletionRequestsRepository _repository;
  late final ReportsRepository _reportsRepository;

  late Future<_DeletionRequestsViewData> _screenFuture;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository;
    _reportsRepository = widget.reportsRepository;
    _load();
  }

  void _load() {
    setState(() {
      _screenFuture = _loadScreenData();
    });
  }

  Future<_DeletionRequestsViewData> _loadScreenData() async {
    final requests = await _repository.getPendingDeletionRequests();
    final results = await Future.wait([
      _reportsRepository.getReports(),
      _reportsRepository.getInteractionsByReportId(),
    ]);

    final reports = results[0] as List<Report>;
    final interactions = results[1] as Map<String, ReportInteraction>;

    return _DeletionRequestsViewData(
      requests: requests,
      reportsById: {for (final report in reports) report.id: report},
      interactionsByReportId: interactions,
    );
  }

  Future<void> _handleApprove(DeletionRequest request) async {
    await _repository.approveDeletionRequest(request.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Report ${request.reportId} deletion approved.'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
    _load();
  }

  Future<void> _handleReject(DeletionRequest request) async {
    await _repository.rejectDeletionRequest(request.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deletion request for ${request.reportId} rejected.'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        iconTheme: IconThemeData(color: scheme.onPrimary),
        title: const Text(
          'Deletion Requests',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: false,
        leadingWidth: 40,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: FutureBuilder<_DeletionRequestsViewData>(
        future: _screenFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load requests.\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final data = snapshot.data ?? const _DeletionRequestsViewData();
          final requests = data.requests;

          if (requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: scheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No pending deletion requests',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _DeletionRequestCard(
                request: requests[index],
                report: data.reportsById[requests[index].reportId],
                interaction:
                    data.interactionsByReportId[requests[index].reportId],
                onApprove: () => _handleApprove(requests[index]),
                onReject: () => _handleReject(requests[index]),
              );
            },
          );
        },
      ),
    );
  }
}

class _DeletionRequestCard extends StatefulWidget {
  const _DeletionRequestCard({
    required this.request,
    required this.report,
    required this.interaction,
    required this.onApprove,
    required this.onReject,
  });

  final DeletionRequest request;
  final Report? report;
  final ReportInteraction? interaction;
  final Future<void> Function() onApprove;
  final Future<void> Function() onReject;

  @override
  State<_DeletionRequestCard> createState() => _DeletionRequestCardState();
}

class _DeletionRequestCardState extends State<_DeletionRequestCard> {
  bool _isActioning = false;

  Future<void> _action(Future<void> Function() callback) async {
    setState(() => _isActioning = true);
    try {
      await callback();
    } finally {
      if (mounted) {
        setState(() => _isActioning = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final request = widget.request;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            _ReportDetailsCard(
              reportId: request.reportId,
              report: widget.report,
              interaction: widget.interaction,
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            
            Row(
              children: [
                Icon(Icons.people_outline, size: 18, color: scheme.primary),
                const SizedBox(width: 6),
                Text(
                  '${request.requestedByIds.length} '
                  '${request.requestedByIds.length == 1 ? 'person' : 'people'} requested deletion',
                  style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  'First requested on ${_formatDate(request.createdAt)}',
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Text(
              'Reasons',
              style: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            ...List.generate(request.reasons.length, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Icon(
                        Icons.circle,
                        size: 6,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(request.reasons[i], style: text.bodySmall),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 16),

            if (_isActioning)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _action(widget.onReject),
                      icon: const Icon(Icons.close),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: scheme.error,
                        iconColor: scheme.error,
                        side: BorderSide(color: scheme.error),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _action(widget.onApprove),
                      icon: const Icon(Icons.check),
                      label: const Text('Approve'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: scheme.primary,
                        iconColor: scheme.primary,
                        side: BorderSide(color: scheme.primary),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ReportDetailsCard extends StatelessWidget {
  const _ReportDetailsCard({
    required this.reportId,
    required this.report,
    required this.interaction,
  });

  final String reportId;
  final Report? report;
  final ReportInteraction? interaction;

  String _statusLabel(ReportStatus status) {
    return switch (status) {
      ReportStatus.reported => 'Reported',
      ReportStatus.assigned => 'Assigned',
      ReportStatus.underReview => 'Under Review',
      ReportStatus.underWork => 'Under Work',
      ReportStatus.repaired => 'Repaired',
    };
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final activeReport = report;
    final status = interaction?.reportStatus ?? ReportStatus.reported;

    if (activeReport == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.errorContainer.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.error.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: scheme.error),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Report not found (ID: $reportId). It may have already been removed.',
                style: text.bodySmall,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.report_problem_outlined, color: scheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        activeReport.title,
                        style: text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusBadge(label: _statusLabel(status)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  activeReport.description,
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  'ID: ${activeReport.id} • Category: ${activeReport.category}',
                  style: text.labelSmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: scheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

class _DeletionRequestsViewData {
  const _DeletionRequestsViewData({
    this.requests = const [],
    this.reportsById = const {},
    this.interactionsByReportId = const {},
  });

  final List<DeletionRequest> requests;
  final Map<String, Report> reportsById;
  final Map<String, ReportInteraction> interactionsByReportId;
}
