import 'package:civic_scope/core/utils/constants/enums.dart';
import 'package:civic_scope/features/reports/data/reports_reposritory.dart';
import 'package:civic_scope/features/roles/admin/data/deletion_requests/deletion_requests_repository.dart';
import 'package:civic_scope/features/roles/admin/domain/deletion_requests/deletion_request.dart';
import 'package:civic_scope/features/roles/admin/presentation/deletion_requests_list/deletion_requests_list_screen.dart';
import 'package:civic_scope/shared/models/report_interaction_model.dart';
import 'package:civic_scope/shared/models/report_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_preferences.dart';

class FakeDeletionRequestsRepository implements DeletionRequestsRepository {
  FakeDeletionRequestsRepository(this.requests);

  final List<DeletionRequest> requests;
  int approveCallCount = 0;
  int rejectCallCount = 0;

  @override
  Future<List<DeletionRequest>> getDeletionRequests() async => List<DeletionRequest>.from(requests);

  @override
  Future<void> createOrUpdateDeletionRequest({
    required String reportId,
    required String requesterId,
    required List<String> reasons,
  }) async {
    requests.add(
      DeletionRequest(
        id: 'generated-${requests.length + 1}',
        reportId: reportId,
        requestedByIds: [requesterId],
        reasons: reasons,
        createdAt: DateTime.utc(2026, 3, 21),
      ),
    );
  }

  @override
  Future<DeletionRequest?> getDeletionRequestById(String id) async {
    for (final request in requests) {
      if (request.id == id) return request;
    }
    return null;
  }

  @override
  Future<List<DeletionRequest>> getPendingDeletionRequests() async {
    return requests
        .where((request) => request.status == DeletionRequestStatus.pending)
        .toList();
  }

  @override
  Future<void> approveDeletionRequest(String id) async {
    approveCallCount += 1;
    final index = requests.indexWhere((request) => request.id == id);
    requests[index] = requests[index].copyWith(status: DeletionRequestStatus.approved);
  }

  @override
  Future<void> rejectDeletionRequest(String id) async {
    rejectCallCount += 1;
    final index = requests.indexWhere((request) => request.id == id);
    requests[index] = requests[index].copyWith(status: DeletionRequestStatus.rejected);
  }
}

class FakeReportsRepository implements ReportsRepository {
  FakeReportsRepository({required this.reports, required this.interactions});

  final List<Report> reports;
  final Map<String, ReportInteraction> interactions;

  @override
  Future<void> submitReport(Report report) async {
    reports.add(report);
  }

  @override
  Future<void> submitInteraction(ReportInteraction interaction) async {
    interactions[interaction.reportID] = interaction;
  }

  @override
  Future<ReportInteraction?> getInteraction(String reportID) async => interactions[reportID];

  @override
  Future<void> updateInteraction(ReportInteraction interaction) async {
    interactions[interaction.reportID] = interaction;
  }

  @override
  Future<void> incrementUpvote({required String reportId, required bool increase}) async {}

  @override
  Future<void> addComment({required String reportId, required Comment comment}) async {}

  @override
  Future<List<Report>> getReports() async => reports;

  @override
  Future<Map<String, ReportInteraction>> getInteractionsByReportId() async => interactions;
}

void main() {
  testWidgets('renders deletion requests and supports approving a request', (tester) async {
    final prefs = await setUpTestPrefs();
    final requestRepo = FakeDeletionRequestsRepository([
      DeletionRequest(
        id: 'req-1',
        reportId: 'rep-1',
        requestedByIds: const ['user-1', 'user-2'],
        reasons: const ['Duplicate', 'Already fixed'],
        createdAt: DateTime.utc(2026, 3, 20),
      ),
    ]);
    final reportsRepo = FakeReportsRepository(
      reports: [
        Report(
          'rep-1',
          'Large pothole',
          'alice',
          'pothole',
          'Main road damage',
          'https://example.com/evidence.jpg',
          52.48,
          -1.89,
          DateTime.utc(2026, 3, 19),
        ),
      ],
      interactions: {
        'rep-1': ReportInteraction(
          'rep-1',
          ReportStatus.assigned,
          4,
          [Comment('bob', 'Needs urgent repair')],
          DateTime.utc(2026, 3, 20),
        ),
      },
    );

    await tester.pumpWidget(
      buildProviderApp(
        prefs: prefs,
        child: DeletionRequestsListScreen(
          repository: requestRepo,
          reportsRepository: reportsRepo,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Deletion Requests'), findsOneWidget);
    expect(find.text('Large pothole'), findsOneWidget);
    expect(find.text('Reasons'), findsOneWidget);
    expect(find.text('Approve'), findsOneWidget);

    await tester.tap(find.text('Approve'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(requestRepo.approveCallCount, 1);
    expect(find.textContaining('deletion approved'), findsOneWidget);
    expect(find.text('No pending deletion requests'), findsOneWidget);
  });
}
