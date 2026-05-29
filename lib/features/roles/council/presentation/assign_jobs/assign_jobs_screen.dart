import 'package:civic_scope/features/reports/data/reports_reposritory.dart';
import 'package:civic_scope/features/roles/council/data/assign_jobs/assign_jobs_repository.dart';
import 'package:civic_scope/features/roles/council/data/register_company/register_company_repository.dart';
import 'package:civic_scope/core/utils/constants/enums.dart';
import 'package:civic_scope/shared/models/company_model.dart';
import 'package:civic_scope/shared/models/job_assigment_model.dart';
import 'package:civic_scope/shared/models/report_interaction_model.dart';
import 'package:civic_scope/shared/models/report_model.dart';
import 'package:civic_scope/shared/widgets/empty_state_view.dart';
import 'package:flutter/material.dart';

class AssignJobsScreen extends StatefulWidget {
  const AssignJobsScreen({super.key});

  @override
  State<AssignJobsScreen> createState() => _AssignJobsScreenState();
}

class _AssignJobsScreenState extends State<AssignJobsScreen> {
  final _registercompanyrepository = RegisterCompanyRepository();
  final _assignJobsRepository = AssignJobsRepository();
  final _reportsRepository = ReportsRepository();

  List<Company> _companies = const [];
  List<_ReportAssignmentRow> _rows = const [];

  bool _isLoading = true;
  String? _error;
  String? _assigningReportId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _reportsRepository.getReports(),
        _reportsRepository.getInteractionsByReportId(),
        _assignJobsRepository.getJobAssignments(),
        _registercompanyrepository.getRegisteredCompanies(),
      ]);

      final reports = results[0] as List<Report>;
      if (reports.isEmpty) debugPrint("ErrorHere");
      final interactions = results[1] as Map<String, ReportInteraction>;
      if (interactions.isEmpty) debugPrint("ErrorHere");
      final jobs = results[2] as List<JobAssignment>;
      if (jobs.isEmpty) debugPrint("ErrorHere");
      final companies = results[3] as List<Company>;
      if (companies.isEmpty) debugPrint("ErrorHere");

      final jobsByReportId = {for (final job in jobs) job.reportId: job};
      final companyNameById = {
        for (final company in companies) company.id: company.name,
      };

      final rows = reports.map((report) {
        final interaction =
            interactions[report.id] ??
            ReportInteraction(
              report.id,
              ReportStatus.reported,
              0,
              const <Comment>[],
              DateTime.now().toUtc(),
            );

        final job = jobsByReportId[report.id];
        final assignedCompanyName = job?.assignedCompanyId == null
            ? null
            : companyNameById[job!.assignedCompanyId!] ?? job.assignedCompanyId;

        return _ReportAssignmentRow(
          report: report,
          interaction: interaction,
          assignment: job,
          assignedCompanyName: assignedCompanyName,
        );
      }).toList();

      rows.sort((a, b) {
        // Keep repaired reports at the bottom regardless of votes/date.
        final aRepaired = a.interaction.reportStatus == ReportStatus.repaired;
        final bRepaired = b.interaction.reportStatus == ReportStatus.repaired;
        if (aRepaired != bRepaired) {
          return aRepaired ? 1 : -1;
        }

        if (a.canAssign != b.canAssign) {
          return a.canAssign ? -1 : 1;
        }
        if (a.interaction.upvotes != b.interaction.upvotes) {
          return b.interaction.upvotes.compareTo(a.interaction.upvotes);
        }
        return b.report.created.compareTo(a.report.created);
      });

      if (!mounted) return;
      setState(() {
        _companies = companies;
        _rows = rows;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Failed to load jobs.\n$_error',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_rows.isEmpty) {
      return const EmptyStateView(
        icon: Icons.assignment_outlined,
        message: 'No reports available for assignment.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _rows.length,
        itemBuilder: (context, index) {
          final row = _rows[index];
          final status = _statusLabel(row.interaction.reportStatus);
          final isAssigning = _assigningReportId == row.report.id;

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: Icon(
                row.canAssign
                    ? Icons.assignment_late_outlined
                    : Icons.assignment_turned_in_outlined,
                color: scheme.primary,
              ),
              title: Text(row.report.title),
              subtitle: Text(
                'Votes: ${row.interaction.upvotes}\n'
                'Status: $status\n'
                '${row.canAssign ? 'Pending assignment' : 'Assigned to: ${row.assignedCompanyName ?? 'Unknown company'}'}',
              ),
              isThreeLine: true,
              trailing: row.canAssign &&
                      row.interaction.reportStatus != ReportStatus.repaired
                  ? OutlinedButton(
                      onPressed: isAssigning
                          ? null
                          : () => _showAssignCompanySheet(row),
                      child: isAssigning
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Assign'),
                    )
                  : Text(
                      row.interaction.reportStatus == ReportStatus.repaired
                          ? 'Repaired'
                          : 'Assigned',
                    ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showAssignCompanySheet(_ReportAssignmentRow row) async {
    final companies = _companies;

    if (companies.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No companies available for assignment.')),
      );
      return;
    }

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        String query = '';

        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filtered = companies.where((company) {
              final normalized = query.trim().toLowerCase();
              if (normalized.isEmpty) return true;
              return company.name.toLowerCase().contains(normalized) ||
                  company.id.toLowerCase().contains(normalized);
            }).toList();

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assign "${row.report.title}"',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search companies by name or UID',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        setSheetState(() {
                          query = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    if (filtered.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 18),
                        child: EmptyStateView(
                          icon: Icons.search_off_outlined,
                          message: 'No matching companies found.',
                          iconSize: 44,
                        ),
                      )
                    else
                      SizedBox(
                        height: 280,
                        child: ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final company = filtered[index];
                            return ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.business),
                              ),
                              title: Text(company.name),
                              subtitle: Text('UID: ${company.id}'),
                              trailing: ElevatedButton(
                                onPressed: () async {
                                  Navigator.of(context).pop();
                                  await _assignReportToCompany(row, company);
                                },
                                child: const Text('Select'),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _assignReportToCompany(
    _ReportAssignmentRow row,
    Company company,
  ) async {
    setState(() {
      _assigningReportId = row.report.id;
    });

    final updatedInteraction = ReportInteraction(
      row.interaction.reportID,
      ReportStatus.assigned,
      row.interaction.upvotes,
      row.interaction.comments,
      DateTime.now().toUtc(),
    );

    final assignment = JobAssignment(
      id: row.report.id,
      reportId: row.report.id,
      reportTitle: row.report.title,
      priority: _priorityForVotes(row.interaction.upvotes),
      assignedCompanyId: company.id,
      assignedWorkerId: "",
    );

    try {
      await _assignJobsRepository.assignJob(updatedInteraction, assignment);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Assigned to ${company.name} (${company.id})')),
      );
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not assign job: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _assigningReportId = null;
        });
      }
    }
  }

  String _priorityForVotes(int upvotes) {
    if (upvotes >= 20) return 'High';
    if (upvotes >= 8) return 'Medium';
    return 'Low';
  }

  String _statusLabel(ReportStatus status) {
    return status.name;
  }
}

class _ReportAssignmentRow {
  const _ReportAssignmentRow({
    required this.report,
    required this.interaction,
    required this.assignment,
    required this.assignedCompanyName,
  });

  final Report report;
  final ReportInteraction interaction;
  final JobAssignment? assignment;
  final String? assignedCompanyName;

  bool get canAssign {
    return interaction.reportStatus == ReportStatus.reported &&
        assignment == null;
  }
}
