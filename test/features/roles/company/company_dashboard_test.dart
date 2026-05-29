import 'package:civic_scope/core/routing/app_routes.dart';
import 'package:civic_scope/core/utils/constants/enums.dart';
import 'package:civic_scope/features/roles/company/data/company_repository.dart';
import 'package:civic_scope/features/roles/company/presentation/company_dashboard/company_dashboard_screen.dart';
import 'package:civic_scope/shared/models/job_assigment_model.dart';
import 'package:civic_scope/shared/models/report_interaction_model.dart';
import 'package:civic_scope/shared/models/users_model.dart';
import 'package:civic_scope/shared/providers/auth_provider.dart';
import 'package:civic_scope/shared/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../helpers/test_app.dart';
import '../../../helpers/test_preferences.dart';

class FakeCompanyRepository implements CompanyRepository {
  FakeCompanyRepository({
    required this.jobs,
    required this.employees,
    required this.interactions,
  });

  final List<JobAssignment> jobs;
  final List<AppUser> employees;
  final Map<String, ReportInteraction> interactions;

  int updateJobAssignmentCallCount = 0;
  int updateReportInteractionStatusCallCount = 0;
  int removeWorkerFromCompanyCallCount = 0;
  JobAssignment? lastUpdatedAssignment;
  String? lastUpdatedReportId;
  ReportStatus? lastUpdatedStatus;
  String? lastRemovedWorkerId;

  @override
  Future<List<JobAssignment>> getAssignedJobs(String companyId) async => List<JobAssignment>.from(jobs);

  @override
  Future<List<AppUser>> getCompanyEmployees(String companyId) async => List<AppUser>.from(employees);

  @override
  Future<Map<String, ReportInteraction>> getInteractionsByReportIds(List<String> reportIds) async {
    return {
      for (final reportId in reportIds)
        if (interactions.containsKey(reportId)) reportId: interactions[reportId]!,
    };
  }

  @override
  Future<void> updateJobAssignment(JobAssignment assignment) async {
    updateJobAssignmentCallCount += 1;
    lastUpdatedAssignment = assignment;
    final index = jobs.indexWhere((job) => job.id == assignment.id);
    if (index != -1) {
      jobs[index] = assignment;
    }
  }

  @override
  Future<void> updateReportInteractionStatus(String reportId, ReportStatus newStatus) async {
    updateReportInteractionStatusCallCount += 1;
    lastUpdatedReportId = reportId;
    lastUpdatedStatus = newStatus;
    final interaction = interactions[reportId];
    if (interaction != null) {
      interactions[reportId] = ReportInteraction(
        interaction.reportID,
        newStatus,
        interaction.upvotes,
        interaction.comments,
        interaction.lastModified,
      );
    }
  }

  @override
  Future<void> removeWorkerFromCompany(String workerId) async {
    removeWorkerFromCompanyCallCount += 1;
    lastRemovedWorkerId = workerId;
  }


  @override
  Future<void> addWorkerToCompany(String workerEmail, String companyId) async {}
}

GoRouter _buildDashboardRouter(CompanyDashboardScreen screen) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, _) => screen),
      GoRoute(
        path: AppRoutes.companyAddWorker,
        builder: (_, _) => const Scaffold(body: Text('Add worker route')),
      ),
    ],
  );
}

void main() {
  

  testWidgets('renders jobs and assigns a worker through the bottom sheet', (tester) async {
    final prefs = await setUpTestPrefs();
    final repository = FakeCompanyRepository(
      jobs: [
        const JobAssignment(
          id: 'job-1',
          reportId: 'rep-1',
          reportTitle: 'Blocked drain',
          priority: 'high',
          assignedCompanyId: 'comp-1',
        ),
      ],
      employees: [
        AppUser(
          uid: 'worker-1',
          email: 'alice@example.com',
          displayName: 'Alice',
          role: UserRole.worker,
          companyId: 'comp-1',
        ),
      ],
      interactions: {
        'rep-1': ReportInteraction(
          'rep-1',
          ReportStatus.assigned,
          0,
          [],
          DateTime.utc(2026, 3, 20),
        ),
      },
    );
    final router = _buildDashboardRouter(CompanyDashboardScreen(companyRepository: repository));

    await tester.pumpWidget(
      buildRouterApp(
        router: router,
        prefs: prefs,
        overrides: [
          authStateProvider.overrideWithValue(AppAuthState.authenticated),
          currentUserCompanyIdProvider.overrideWithValue('comp-1'),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Blocked drain'), findsOneWidget);
    expect(find.text('Assign'), findsOneWidget);

    await tester.tap(find.text('Assign'));
    await tester.pumpAndSettle();

    expect(find.text('Assign "Blocked drain" to:'), findsOneWidget);
    expect(find.text('Alice'), findsOneWidget);

    await tester.tap(find.text('Select'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(repository.updateJobAssignmentCallCount, 1);
    expect(repository.lastUpdatedAssignment?.assignedWorkerId, 'worker-1');
    expect(repository.updateReportInteractionStatusCallCount, 1);
    expect(repository.lastUpdatedReportId, 'rep-1');
    expect(repository.lastUpdatedStatus, ReportStatus.underReview);
    expect(find.text('Assigned to Alice.'), findsOneWidget);
  });

  testWidgets('renders workers and removes a worker after confirmation', (tester) async {
    final prefs = await setUpTestPrefs();
    final repository = FakeCompanyRepository(
      jobs: const [],
      employees: [
        AppUser(
          uid: 'worker-1',
          email: 'alice@example.com',
          displayName: 'Alice',
          role: UserRole.worker,
          companyId: 'comp-1',
        ),
      ],
      interactions: const {},
    );
    final router = _buildDashboardRouter(CompanyDashboardScreen(companyRepository: repository));

    await tester.pumpWidget(
      buildRouterApp(
        router: router,
        prefs: prefs,
        overrides: [
          authStateProvider.overrideWithValue(AppAuthState.authenticated),
          currentUserCompanyIdProvider.overrideWithValue('comp-1'),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('My Workers'));
    await tester.pumpAndSettle();

    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Remove Worker'), findsOneWidget);

    await tester.tap(find.text('Remove Worker'));
    await tester.pumpAndSettle();
    expect(find.text('Remove Alice from this company?'), findsOneWidget);

    await tester.tap(find.text('Remove').last);
    await tester.pumpAndSettle();

    expect(repository.removeWorkerFromCompanyCallCount, 1);
    expect(repository.lastRemovedWorkerId, 'worker-1');
    expect(find.text('Alice removed from company.'), findsOneWidget);
  });
}
