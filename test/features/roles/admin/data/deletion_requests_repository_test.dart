import 'package:civic_scope/features/roles/admin/data/deletion_requests/deletion_requests_repository.dart';
import 'package:civic_scope/features/roles/admin/domain/deletion_requests/deletion_request.dart';
import 'package:flutter_test/flutter_test.dart';

class InMemoryDeletionRequestsRepository implements DeletionRequestsRepository {
  final Map<String, DeletionRequest> _requests = <String, DeletionRequest>{};

  @override
  Future<List<DeletionRequest>> getDeletionRequests() async {
    final requests = _requests.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return requests;
  }

  @override
  Future<void> createOrUpdateDeletionRequest({
    required String reportId,
    required String requesterId,
    required List<String> reasons,
  }) async {
    final cleanReasons = reasons
        .map((reason) => reason.trim())
        .where((reason) => reason.isNotEmpty)
        .toList();

    final existing = _requests.values.where((request) {
      return request.reportId == reportId &&
          request.status == DeletionRequestStatus.pending;
    }).toList();

    if (existing.isNotEmpty) {
      final request = existing.first;
      final requesters = [...request.requestedByIds];
      if (!requesters.contains(requesterId)) {
        requesters.add(requesterId);
      }
      _requests[request.id] = request.copyWith(
        requestedByIds: requesters,
        reasons: [...request.reasons, ...cleanReasons],
      );
      return;
    }

    final id = 'req-${_requests.length + 1}';
    _requests[id] = DeletionRequest(
      id: id,
      reportId: reportId,
      requestedByIds: [requesterId],
      reasons: cleanReasons,
      createdAt: DateTime.utc(2026, 3, 20, 10, _requests.length),
    );
  }

  @override
  Future<List<DeletionRequest>> getPendingDeletionRequests() async {
    return (await getDeletionRequests())
        .where((request) => request.status == DeletionRequestStatus.pending)
        .toList();
  }

  @override
  Future<DeletionRequest?> getDeletionRequestById(String id) async => _requests[id];

  @override
  Future<void> approveDeletionRequest(String id) async {
    final request = _requests[id];
    if (request == null) throw StateError('Deletion request not found: $id');
    _requests[id] = request.copyWith(status: DeletionRequestStatus.approved);
  }

  @override
  Future<void> rejectDeletionRequest(String id) async {
    final request = _requests[id];
    if (request == null) throw StateError('Deletion request not found: $id');
    _requests[id] = request.copyWith(status: DeletionRequestStatus.rejected);
  }
}

void main() {
  group('DeletionRequestsRepository contract', () {
    late InMemoryDeletionRequestsRepository repository;

    setUp(() {
      repository = InMemoryDeletionRequestsRepository();
    });

    test('createOrUpdateDeletionRequest creates a new request for a new report', () async {
      await repository.createOrUpdateDeletionRequest(
        reportId: 'rep_test_new',
        requesterId: 'user_test',
        reasons: const ['Resolved already'],
      );

      final requests = await repository.getDeletionRequests();
      final created = requests.single;

      expect(created.reportId, 'rep_test_new');
      expect(created.requestedByIds, ['user_test']);
      expect(created.reasons, ['Resolved already']);
      expect(created.status, DeletionRequestStatus.pending);
    });

    test('createOrUpdateDeletionRequest appends requester and reasons when report already exists', () async {
      await repository.createOrUpdateDeletionRequest(
        reportId: 'rep_test_update',
        requesterId: 'user_one',
        reasons: const ['Duplicate'],
      );
      await repository.createOrUpdateDeletionRequest(
        reportId: 'rep_test_update',
        requesterId: 'user_two',
        reasons: const ['Already fixed'],
      );

      final updated = (await repository.getDeletionRequests()).single;

      expect(updated.requestedByIds, containsAll(['user_one', 'user_two']));
      expect(updated.reasons, containsAll(['Duplicate', 'Already fixed']));
    });

    test('getPendingDeletionRequests returns only pending requests', () async {
      await repository.createOrUpdateDeletionRequest(
        reportId: 'rep_pending',
        requesterId: 'user_pending',
        reasons: const ['Spam'],
      );
      final request = (await repository.getDeletionRequests()).single;
      await repository.approveDeletionRequest(request.id);
      await repository.createOrUpdateDeletionRequest(
        reportId: 'rep_pending_2',
        requesterId: 'user_pending_2',
        reasons: const ['Duplicate'],
      );

      final requests = await repository.getPendingDeletionRequests();

      expect(requests.length, 1);
      expect(requests.single.reportId, 'rep_pending_2');
    });

    test('approveDeletionRequest updates the request status to approved', () async {
      await repository.createOrUpdateDeletionRequest(
        reportId: 'rep_test_approve',
        requesterId: 'user_approve',
        reasons: const ['Spam'],
      );
      final request = (await repository.getDeletionRequests()).single;

      await repository.approveDeletionRequest(request.id);
      final after = await repository.getDeletionRequestById(request.id);

      expect(after?.status, DeletionRequestStatus.approved);
    });

    test('rejectDeletionRequest updates the request status to rejected', () async {
      await repository.createOrUpdateDeletionRequest(
        reportId: 'rep_test_reject',
        requesterId: 'user_reject',
        reasons: const ['Private property'],
      );
      final request = (await repository.getDeletionRequests()).single;

      await repository.rejectDeletionRequest(request.id);
      final after = await repository.getDeletionRequestById(request.id);

      expect(after?.status, DeletionRequestStatus.rejected);
    });
  });
}
