import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:civic_scope/features/roles/company/data/company_repository.dart';
import 'package:civic_scope/shared/models/job_assigment_model.dart';
import 'package:civic_scope/shared/models/report_interaction_model.dart';
import 'package:civic_scope/shared/models/users_model.dart';
import 'package:civic_scope/core/utils/constants/enums.dart';
import 'package:civic_scope/shared/providers/auth_provider.dart';
import 'package:civic_scope/shared/providers/user_provider.dart';
import 'package:civic_scope/shared/widgets/empty_state_view.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/routing/app_routes.dart';

class CompanyDashboardScreen extends ConsumerStatefulWidget {
  CompanyDashboardScreen({
    super.key,
    CompanyRepository? companyRepository,
  }) : companyRepository = companyRepository ?? CompanyRepository();

  final CompanyRepository companyRepository;

  @override
  ConsumerState<CompanyDashboardScreen> createState() => _CompanyDashboardScreenState();
}

class _CompanyDashboardScreenState extends ConsumerState<CompanyDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final CompanyRepository _companyRepository;
  //final _companyRepository = CompanyRepository();
  late Future<List<JobAssignment>> _jobsFuture;
  late Future<List<AppUser>> _employeesFuture;
  String? _loadedCompanyId;

  @override
  void initState() {
    super.initState();
     _companyRepository = widget.companyRepository;
    _tabController = TabController(length: 2, vsync: this);
    _jobsFuture = Future.value(const <JobAssignment>[]);
    _employeesFuture = Future.value(const <AppUser>[]);

    ref.listenManual<String?>(
      currentUserCompanyIdProvider,
      (_, nextCompanyId) {
        if (nextCompanyId == null) {
          if (!mounted) return;
          setState(() {
            _loadedCompanyId = null;
            _jobsFuture = Future.value(const <JobAssignment>[]);
            _employeesFuture = Future.value(const <AppUser>[]);
          });
          return;
        }

        if (_loadedCompanyId == nextCompanyId) return;
        _load(nextCompanyId);
      },
      fireImmediately: true,
    );
  }

  void _load(String companyId) {
    setState(() {
      _loadedCompanyId = companyId;
      _jobsFuture = _companyRepository.getAssignedJobs(companyId);
      _employeesFuture =
          _companyRepository.getCompanyEmployees(companyId);
    });
  }

  Future<void> _refresh() {
    if (_loadedCompanyId == null) return Future.value();
    return Future.delayed(const Duration(milliseconds: 500)).then((_) {
      _load(_loadedCompanyId!);
    });
  }

  Future<void> _removeWorkerFromCompany(AppUser worker) async {
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Remove Worker'),
          content: Text(
            'Remove ${worker.displayName} from this company?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _companyRepository.removeWorkerFromCompany(worker.uid);

      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('${worker.displayName} removed from company.'),
        ),
      );
      if (_loadedCompanyId != null) {
        _load(_loadedCompanyId!);
      }
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Could not remove worker: $e'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isAuthenticated =
        ref.watch(authStateProvider) == AppAuthState.authenticated;
    final companyId = ref.watch(currentUserCompanyIdProvider);

    if (!isAuthenticated) {
      return Scaffold(
        appBar: AppBar(
          toolbarHeight: 74,
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          iconTheme: IconThemeData(color: scheme.onPrimary),
          title: const Text(
            'Company Dashboard',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          centerTitle: false,
          leadingWidth: 40,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        body: const EmptyStateView(
          icon: Icons.lock_outline,
          message: 'Please log in to access the company dashboard.',
        ),
      );
    }

    if (companyId == null) {
      return Scaffold(
        appBar: AppBar(
          toolbarHeight: 74,
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          iconTheme: IconThemeData(color: scheme.onPrimary),
          title: const Text(
            'Company Dashboard',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          centerTitle: false,
          leadingWidth: 40,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        body: const EmptyStateView(
          icon: Icons.business_outlined,
          message: 'Your account is not linked to a company yet.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 74,
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        iconTheme: IconThemeData(color: scheme.onPrimary),
        title: const Text(
          'Company Dashboard',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: false,
        leadingWidth: 40,
        elevation: 0,
        scrolledUnderElevation: 0,

        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Material(
            color: scheme.surface,
            child: TabBar(
              controller: _tabController,
              labelColor: scheme.primary,
              unselectedLabelColor: scheme.onSurfaceVariant,
              indicatorColor: scheme.primary,
              tabs: const [
                Tab(icon: Icon(Icons.assignment), text: 'Pending Jobs'),
                Tab(icon: Icon(Icons.engineering), text: 'My Workers'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildJobsTab(), _buildWorkersTab()],
      ),
      // 悬浮按钮：用于注册新工人
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // 跳转到添加工人页面
          await context.push(AppRoutes.companyAddWorker);
          if (!mounted) return;
          _load(companyId);
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Add Worker'),
      ),
    );
  }

  // 构建任务列表页
  Widget _buildJobsTab() {
    final scheme = Theme.of(context).colorScheme;

    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        _jobsFuture,
        _employeesFuture,
        _jobsFuture.then((jobs) {
          final reportIds = jobs.map((job) => job.reportId).toList();
          return _companyRepository.getInteractionsByReportIds(reportIds);
        }),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Failed to load assigned jobs.\n${snapshot.error}',
              textAlign: TextAlign.center,
            ),
          );
        }

        final jobs = (snapshot.data?[0] as List<JobAssignment>?) ??
            const <JobAssignment>[];
        final employees = (snapshot.data?[1] as List<AppUser>?) ??
            const <AppUser>[];
        final interactionsByReportId =
          (snapshot.data?[2] as Map<String, ReportInteraction>?) ??
          <String, ReportInteraction>{};

        final workerNameById = {
          for (final employee in employees) employee.uid: employee.displayName,
        };

        final sortedJobs = [...jobs]
          ..sort((a, b) {
          final aStatus =
            interactionsByReportId[a.reportId]?.reportStatus ??
            ReportStatus.assigned;
          final bStatus =
            interactionsByReportId[b.reportId]?.reportStatus ??
            ReportStatus.assigned;

          final aRepaired = aStatus == ReportStatus.repaired;
          final bRepaired = bStatus == ReportStatus.repaired;
          if (aRepaired != bRepaired) return aRepaired ? 1 : -1;

            final aAssigned = a.assignedWorkerId != null;
            final bAssigned = b.assignedWorkerId != null;

            if (aAssigned == bAssigned) return 0;
            return aAssigned ? 1 : -1;
          });

        if (sortedJobs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.assignment_late_outlined,
                  size: 56,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(height: 10),
                const Text('No jobs currently assigned to this company.'),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: sortedJobs.length + 1,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              if (index == sortedJobs.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: scheme.primary.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Not seeing an assigned job?',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(color: scheme.primary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Pull down to refresh the page.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: scheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final job = sortedJobs[index];
                final status =
                  interactionsByReportId[job.reportId]?.reportStatus ??
                  ReportStatus.assigned;
                final isRepaired = status == ReportStatus.repaired;
              final assignedWorkerName = job.assignedWorkerId == null
                  ? null
                  : workerNameById[job.assignedWorkerId!] ?? 'Unknown Worker';
              final isAssignedToWorker = assignedWorkerName != null;

              return Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  leading: Icon(
                    Icons.warning_amber_rounded,
                    color: Theme.of(context).colorScheme.warning,
                  ),
                  title: Text(job.reportTitle),
                  subtitle: Text(
                    isAssignedToWorker
                        ? 'Report: ${job.reportId}\nPriority: ${job.priority}\nStatus: ${status.name}\nAssigned to Worker: $assignedWorkerName'
                        : 'Report: ${job.reportId}\nPriority: ${job.priority}\nStatus: ${status.name}',
                  ),
                  isThreeLine: true,
                  trailing: isRepaired
                      ? const Text('Repaired')
                      : OutlinedButton(
                          onPressed: () {
                            // 触发底部弹窗来分配工人
                            _showAssignWorkerDialog(context, job);
                          },
                          child: Text(
                            isAssignedToWorker ? 'Re-Assign' : 'Assign',
                          ),
                        ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // 构建工人列表页
  Widget _buildWorkersTab() {
    return FutureBuilder<List<AppUser>>(
      future: _employeesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Failed to load workers.\n${snapshot.error}',
              textAlign: TextAlign.center,
            ),
          );
        }

        final workers = snapshot.data ?? const <AppUser>[];
        if (workers.isEmpty) {
          return const EmptyStateView(
            icon: Icons.group_off_outlined,
            message: 'No workers in this company yet.',
          );
        }

        final scheme = Theme.of(context).colorScheme;

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: workers.length,
            itemBuilder: (context, index) {
              final worker = workers[index];
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(worker.displayName),
                subtitle: Text(worker.email),
                trailing: OutlinedButton.icon(
                  onPressed: () => _removeWorkerFromCompany(worker),
                  icon: const Icon(Icons.person_remove_outlined),
                  label: const Text('Remove Worker'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: scheme.error,
                    side: BorderSide(color: scheme.error),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // 这是一个底部弹窗，用于选择工人
  void _showAssignWorkerDialog(BuildContext context, JobAssignment job) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        bool isAssigning = false;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return FutureBuilder<List<AppUser>>(
              future: _employeesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 220,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Failed to load workers.\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final workers = snapshot.data ?? const <AppUser>[];
                if (workers.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: EmptyStateView(
                      icon: Icons.engineering_outlined,
                      message: 'No workers found for this company.',
                      iconSize: 44,
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assign "${job.reportTitle}" to:',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListView.builder(
                        shrinkWrap: true,
                        itemCount: workers.length,
                        itemBuilder: (context, index) {
                          final worker = workers[index];
                          return ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.engineering),
                            ),
                            title: Text(worker.displayName),
                            subtitle: Text(worker.email),
                            trailing: ElevatedButton(
                              onPressed: isAssigning
                                  ? null
                                  : () async {
                                      setSheetState(() => isAssigning = true);

                                      final updatedAssignment = job.copyWith(
                                        assignedWorkerId: worker.uid,
                                      );

                                      try {
                                        await _companyRepository.updateJobAssignment(
                                          updatedAssignment,
                                        );
                                        await _companyRepository
                                            .updateReportInteractionStatus(
                                              job.reportId,
                                              ReportStatus.underReview,
                                            );

                                        if (!context.mounted) return;
                                        context.pop();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Assigned to ${worker.displayName}.',
                                            ),
                                          ),
                                        );
                                        if (_loadedCompanyId != null) {
                                          _load(_loadedCompanyId!);
                                        }
                                      } catch (e) {
                                        if (!context.mounted) return;
                                        setSheetState(() => isAssigning = false);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Could not assign worker: $e',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                              child: isAssigning
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Select'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
