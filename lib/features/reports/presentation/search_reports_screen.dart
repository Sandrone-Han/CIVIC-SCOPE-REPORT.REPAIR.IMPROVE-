import 'package:civic_scope/features/authentication/repositories/user_repository.dart';
import 'package:civic_scope/shared/models/report_interaction_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../data/reports_reposritory.dart';
import 'report_detail.dart';
import '../../home_map/presentation/loading.dart';
import 'package:civic_scope/core/utils/constants/enums.dart';
import 'package:civic_scope/shared/widgets/empty_state_view.dart';

/// This is reports_list.dart
/// This can also be used for the "my reports" functionality in future by
/// passing filterAuthor e.g: SearchReportsScreen(filterAuthor: currentUserId)

// --- Enums ---

enum ReportType { pothole, rubbish, other }

enum SortOption { newestFirst, oldestFirst, mostPopular }

// --- Data Model ---

class CivicReport {
  CivicReport({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.author,
    required this.latitude,
    required this.longitude,
    required this.dateCreated,
    this.status = ReportStatus.reported,
    this.upvotes = 0,
    this.comments = const [],
    this.raisedAmount = 0.0,
    this.fundGoal,
    this.lastModified,
    this.imagePath,
  });

  final String id;
  final String title;
  final String description;
  final ReportType type;
  final ReportStatus status;
  final String author;
  final double latitude;
  final double longitude;
  final DateTime dateCreated;
  final DateTime? lastModified;
  final int upvotes;
  final List<Comment> comments;
  final double raisedAmount;
  final double? fundGoal;
  final String? imagePath;
}

// --- Page ---

class SearchReportsScreen extends StatefulWidget {
  const SearchReportsScreen({super.key, this.filterAuthor});
  final String? filterAuthor;

  @override
  State<SearchReportsScreen> createState() => _SearchReportsScreenState();
}

// --- State ---

class _SearchReportsScreenState extends State<SearchReportsScreen> {
  final _reportsRepository = ReportsRepository();

  ReportType? _filterType;
  SortOption _sortBy = SortOption.newestFirst;

  // --- Label Helpers ---

  String _typeLabel(ReportType t) => switch (t) {
    ReportType.pothole => 'Pothole',
    ReportType.rubbish => 'Rubbish',
    ReportType.other => 'Other',
  };

  String _statusLabel(ReportStatus s) => switch (s) {
    ReportStatus.reported => 'Reported',
    ReportStatus.assigned => 'Assigned',
    ReportStatus.underReview => 'Under Worker Review',
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

  List<CivicReport> _reports = [];
  bool _isloading = true;

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.authStateChanges().first.then((_) {
      _loadReports();
    });
  }

  Future<void> _loadReports() async {
    final reports = await _reportsRepository.getReports();
    final interactions = await _reportsRepository.getInteractionsByReportId();

    final civicReports = reports.map((report) {
      final interaction = interactions[report.id];

      return CivicReport(
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
        status: interaction?.reportStatus ?? ReportStatus.reported,
        upvotes: interaction?.upvotes ?? 0,
        comments: interaction?.comments ?? const <Comment>[],
        imagePath: report.evidenceURL,
      );
    }).toList();

    final filtered = civicReports.where((report) {
      if (widget.filterAuthor != null && report.author != widget.filterAuthor) {
        return false;
      }
      if (_filterType != null && report.type != _filterType) {
        return false;
      }
      return true;
    }).toList();

    switch (_sortBy) {
      case SortOption.newestFirst:
        filtered.sort((a, b) => b.dateCreated.compareTo(a.dateCreated));
      case SortOption.oldestFirst:
        filtered.sort((a, b) => a.dateCreated.compareTo(b.dateCreated));
      case SortOption.mostPopular:
        filtered.sort((a, b) => b.upvotes.compareTo(a.upvotes));
    }

    if (!mounted) return;

    setState(() {
      _reports = filtered;
      _isloading = false;
    });
  }

  // --- Build ---

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    if (_isloading) return LoadingScreen();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        iconTheme: IconThemeData(color: scheme.onPrimary),
        title: Text(
          widget.filterAuthor != null ? 'My Reports' : 'All Reports',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: false,
        leadingWidth: 40,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),

      body: Column(
        children: [
          // --- Filter / Sort Bar ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: scheme.surfaceContainerLow,
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<ReportType?>(
                      value: _filterType,
                      isExpanded: true,
                      hint: const Text('All Types'),
                      dropdownColor: scheme.surface,
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All Types'),
                        ),
                        ...ReportType.values.map(
                          (t) => DropdownMenuItem(
                            value: t,
                            child: Text(_typeLabel(t)),
                          ),
                        ),
                      ],
                      onChanged: (v) {
                        setState(() {
                          _filterType = v;
                          _isloading = true;
                        });
                        _loadReports();
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<SortOption>(
                      value: _sortBy,
                      isExpanded: true,
                      dropdownColor: scheme.surface,
                      items: const [
                        DropdownMenuItem(
                          value: SortOption.newestFirst,
                          child: Text('Newest'),
                        ),
                        DropdownMenuItem(
                          value: SortOption.oldestFirst,
                          child: Text('Oldest'),
                        ),
                        DropdownMenuItem(
                          value: SortOption.mostPopular,
                          child: Text('Popular'),
                        ),
                      ],
                      onChanged: (v) {
                        setState(() {
                          _sortBy = v!;
                          _isloading = true;
                        });
                        _loadReports();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- Report Cards ---
          Expanded(
            child: _reports.isEmpty
                ? EmptyStateView(
                    icon: widget.filterAuthor != null
                        ? Icons.assignment_outlined
                        : Icons.search_off_outlined,
                    message: widget.filterAuthor != null
                        ? 'You have not submitted any reports yet.'
                        : 'No reports found for the selected filters.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _reports.length,
                    itemBuilder: (context, index) {
                      final report = _reports[index];
                      return FutureBuilder(
                        future: UserRepository().getUserById(report.author),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const SizedBox.shrink(); // or a shimmer/spinner
                          }
                          final user = snapshot.data!;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ReportDetailPage(report: report),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      report.title,
                                      style: text.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${user.displayName} · ${_formatDate(report.dateCreated)}',
                                      style: text.bodySmall?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        _chip(
                                          _statusLabel(report.status),
                                          _statusColor(report.status, scheme),
                                          scheme,
                                        ),
                                        const SizedBox(width: 6),
                                        _chip(
                                          _typeLabel(report.type),
                                          scheme.secondaryContainer,
                                          scheme,
                                        ),
                                        const Spacer(),
                                        Icon(
                                          Icons.thumb_up_outlined,
                                          size: 14,
                                          color: scheme.onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${report.upvotes}',
                                          style: text.bodySmall?.copyWith(
                                            color: scheme.onSurfaceVariant,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          Icons.chevron_right,
                                          color: scheme.onSurfaceVariant,
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
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // --- Chip Widget ---

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
