import 'package:civic_scope/features/roles/admin/domain/deletion_requests/deletion_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DeletionRequest', () {
    test('fromJson and toJson round-trip the model', () {
      final request = DeletionRequest.fromJson({
        'id': 'dr_001',
        'reportId': 'rep_001',
        'requestedByIds': ['user_alice', 'user_bob'],
        'reasons': ['Duplicate report', 'Already resolved'],
        'createdAt': '2026-03-01T08:15:00.000Z',
        'status': 'approved',
      });

      final json = request.toJson();

      expect(json['id'], 'dr_001');
      expect(json['reportId'], 'rep_001');
      expect(json['requestedByIds'], ['user_alice', 'user_bob']);
      expect(json['reasons'], ['Duplicate report', 'Already resolved']);
      expect(json['createdAt'], '2026-03-01T08:15:00.000Z');
      expect(json['status'], 'approved');
    });

    test('copyWith updates only supplied fields', () {
      final original = DeletionRequest(
        id: 'dr_001',
        reportId: 'rep_001',
        requestedByIds: const ['user_alice'],
        reasons: const ['Duplicate report'],
        createdAt: DateTime.utc(2026, 3, 1),
      );

      final updated = original.copyWith(
        status: DeletionRequestStatus.rejected,
        reasons: const ['Spam'],
      );

      expect(updated.id, original.id);
      expect(updated.reportId, original.reportId);
      expect(updated.requestedByIds, original.requestedByIds);
      expect(updated.reasons, ['Spam']);
      expect(updated.status, DeletionRequestStatus.rejected);
    });

    test('equality is based on id', () {
      final a = DeletionRequest(
        id: 'same-id',
        reportId: 'rep_a',
        requestedByIds: const ['u1'],
        reasons: const ['x'],
        createdAt: DateTime.utc(2026, 3, 1),
      );
      final b = DeletionRequest(
        id: 'same-id',
        reportId: 'rep_b',
        requestedByIds: const ['u2'],
        reasons: const ['y'],
        createdAt: DateTime.utc(2026, 3, 2),
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });
}
