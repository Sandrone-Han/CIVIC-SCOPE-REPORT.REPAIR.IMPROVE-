import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:civic_scope/features/roles/worker/data/worker_repository.dart';
import 'package:civic_scope/shared/providers/auth_provider.dart';
import 'package:civic_scope/shared/models/job_assigment_model.dart';
import 'package:civic_scope/shared/widgets/empty_state_view.dart';
import '../../../reports/presentation/report_detail.dart';
import '../../../reports/presentation/search_reports_screen.dart';
import 'package:civic_scope/core/utils/constants/enums.dart';

class AssignedJobsScreen extends ConsumerStatefulWidget {
  const AssignedJobsScreen({super.key});

  @override
  ConsumerState<AssignedJobsScreen> createState() => _AssignedJobsScreenState();
}

class _AssignedJobsScreenState extends ConsumerState<AssignedJobsScreen>
    with SingleTickerProviderStateMixin {
  final _workerRepository = WorkerRepository();

  late TabController _tabController;

  List<_WorkerJobRow> activeJobs = [];
  List<_WorkerJobRow> completedJobs = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    ref.listenManual<String?>(currentUserIdProvider, (_, nextWorkerId) {
      if (nextWorkerId == null) {
        if (!mounted) return;
        setState(() {
          activeJobs = [];
          completedJobs = [];
          _isLoading = false;
          _error = null;
        });
        return;
      }

      _loadJobs(nextWorkerId);
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadJobs(String workerId) async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final assignmentsByState = await Future.wait<List<JobAssignment>>([
        _workerRepository.getActiveAssignedJobs(workerId),
        _workerRepository.getCompletedAssignedJobs(workerId),
      ]);

      final activeAssignments = assignmentsByState[0];
      final completedAssignments = assignmentsByState[1];

      final allAssignments = [
        ...activeAssignments,
        ...completedAssignments,
      ];

      final reportIds = allAssignments
          .map((assignment) => assignment.reportId)
          .toSet()
          .toList();
      final reports = await _workerRepository.getReportsByIds(reportIds);
      final interactionsByReportId =
          await _workerRepository.getInteractionsByReportIds(reportIds);

      final reportsById = {for (final report in reports) report.id: report};

      List<_WorkerJobRow> buildRows(List<JobAssignment> assignments) {
        final rows = <_WorkerJobRow>[];

        for (final assignment in assignments) {
          final report = reportsById[assignment.reportId];
          if (report == null) continue;

          final interaction = interactionsByReportId[report.id];
          final status = interaction?.reportStatus ?? ReportStatus.assigned;

          final civicReport = CivicReport(
            id: report.id,
            title: report.title,
            description: report.description,
            type: ReportType.values.firstWhere(
              (value) => value.name == report.category,
              orElse: () => ReportType.other,
            ),
            author: report.author,
            latitude: report.lati,
            longitude: report.long,
            dateCreated: report.created,
            status: status,
            upvotes: interaction?.upvotes ?? 0,
            comments: interaction?.comments ?? const [],
            imagePath: report.evidenceURL,
          );

          rows.add(
            _WorkerJobRow(
              id: civicReport.id,
              title: civicReport.title,
              location: '${civicReport.latitude}, ${civicReport.longitude}',
              severity: _buildSeverity(report.category),
              status: status,
              report: civicReport,
            ),
          );
        }

        rows.sort((a, b) => b.report.dateCreated.compareTo(a.report.dateCreated));
        return rows;
      }

      final loadedActiveJobs = buildRows(activeAssignments);
      final loadedCompletedJobs = buildRows(completedAssignments);

      if (!mounted) return;
      setState(() {
        activeJobs = loadedActiveJobs;
        completedJobs = loadedCompletedJobs;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  String _statusLabel(ReportStatus status) {
    switch (status) {
      case ReportStatus.reported:
        return 'Reported';
      case ReportStatus.assigned:
        return 'Assigned';
      case ReportStatus.underReview:
        return 'Under Review';
      case ReportStatus.underWork:
        return 'Under Work';
      case ReportStatus.repaired:
        return 'Completed';
    }
  }

  //dummy system
  String _buildSeverity(String category) {
    switch (category.toLowerCase()) {
      case 'pothole':
        return 'High';
      case 'rubbish':
        return 'Medium';
      default:
        return 'Low';
    }
  }

  Future<void> _updateJobStatus(_WorkerJobRow job, ReportStatus newStatus) async {
    try {
      await _workerRepository.updateReportInteractionStatus(job.id, newStatus);

      setState(() {
        _isLoading = true;
      });

      final workerId = ref.read(currentUserIdProvider);
      if (workerId == null) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        return;
      }

      await _loadJobs(workerId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status updated to ${_statusLabel(newStatus)}'),
          backgroundColor: _getStatusColor(newStatus),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Update failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getStatusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.repaired:
        return Colors.green;
      case ReportStatus.underWork:
        return Colors.orange;
      case ReportStatus.underReview:
      case ReportStatus.assigned:
      case ReportStatus.reported:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isAuthenticated =
        ref.watch(authStateProvider) == AppAuthState.authenticated;

    if (!isAuthenticated) {
      return Scaffold(
        backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
        appBar: AppBar(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          iconTheme: IconThemeData(color: scheme.onPrimary),
          title: const Text(
            'Work Orders',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          centerTitle: false,
          leadingWidth: 40,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        body: const EmptyStateView(
          icon: Icons.lock_outline,
          message: 'Please log in to view assigned jobs.',
        ),
      );
    }

    return Scaffold(
      backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
      appBar: AppBar(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        iconTheme: IconThemeData(color: scheme.onPrimary),
        title: const Text(
          'Work Orders',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: false,
        leadingWidth: 40,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Material(
            color: scheme.surface,
            child: TabBar(
              controller: _tabController,
              labelColor: scheme.primary,
              unselectedLabelColor: scheme.onSurfaceVariant,
              indicatorColor: scheme.primary,
              tabs: const [
                Tab(text: 'ACTIVE'),
                Tab(text: 'HISTORY'),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildEmptyState(
              icon: Icons.error_outline,
              message: 'Could not load your jobs. Please try again.',
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildJobsList(
                  jobs: activeJobs,
                  emptyIcon: Icons.assignment_late_outlined,
                  emptyMessage: "You don't have assigned jobs.",
                ),
                _buildJobsList(
                  jobs: completedJobs,
                  emptyIcon: Icons.task_alt_outlined,
                  emptyMessage: 'No completed jobs yet.',
                ),
              ],
            ),
    );
  }

  Widget _buildJobsList({
    required List<_WorkerJobRow> jobs,
    required IconData emptyIcon,
    required String emptyMessage,
  }) {
    if (jobs.isEmpty) {
      return _buildEmptyState(
        icon: emptyIcon,
        message: emptyMessage,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 12, bottom: 20),
      itemCount: jobs.length,
      itemBuilder: (context, index) {
        final job = jobs[index];
        final status = job.status;
        final report = job.report;

        //this is where it links with report detail to reroute there
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ReportDetailPage(report: report),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          job.id,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildSeverityChip(job.severity),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    job.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                  Text(
                    job.location,
                    style: TextStyle(color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Divider(height: 30),
                  Row(
                    children: [
                      Icon(
                        status == ReportStatus.repaired
                            ? Icons.check_circle
                            : Icons.engineering,
                        color: _getStatusColor(status),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _statusLabel(status).toUpperCase(),
                          style: TextStyle(
                            color: _getStatusColor(status),
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Spacer(),
                      FilledButton.tonal(
                        onPressed: () => _showUpdateStatusDialog(context, job),
                        child: const Text('Update'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
  }) {
    return EmptyStateView(
      icon: icon,
      message: message,
    );
  }

  Widget _buildSeverityChip(String severity) {
    final color = severity == 'High'
        ? Colors.red
        : (severity == 'Medium' ? Colors.orange : Colors.green);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        severity,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showUpdateStatusDialog(BuildContext context, _WorkerJobRow job) {
    final ReportStatus currentStatus = job.status;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Update Job: ${job.id}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (currentStatus != ReportStatus.repaired)
                ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: const Text('Mark as Completed'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _updateJobStatus(job, ReportStatus.repaired);
                  },
                ),
              if (currentStatus == ReportStatus.underReview)
                ListTile(
                  leading: const Icon(Icons.engineering, color: Colors.orange),
                  title: const Text('Mark as Under Work'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _updateJobStatus(job, ReportStatus.underWork);
                  },
                ),
              if (currentStatus == ReportStatus.repaired)
                ListTile(
                  leading: const Icon(Icons.play_arrow, color: Colors.blue),
                  title: const Text('Re-open Job'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _updateJobStatus(job, ReportStatus.underWork);
                  },
                ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}

class _WorkerJobRow {
  const _WorkerJobRow({
    required this.id,
    required this.title,
    required this.location,
    required this.severity,
    required this.status,
    required this.report,
  });

  final String id;
  final String title;
  final String location;
  final String severity;
  final ReportStatus status;
  final CivicReport report;
}
