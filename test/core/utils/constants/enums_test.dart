import 'package:civic_scope/core/utils/constants/enums.dart';
import 'package:civic_scope/features/roles/admin/domain/deletion_requests/deletion_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppAuthState', () {
    test('exposes expected values', () {
      expect(
        AppAuthState.values.map((e) => e.name),
        ['authenticated', 'unauthenticated', 'loading', 'error'],
      );
    });
  });

  group('UserRole', () {
    test('exposes expected roles', () {
      expect(
        UserRole.values.map((e) => e.name),
        ['guest', 'citizen', 'worker', 'company', 'council', 'admin'],
      );
    });
  });

  group('ReportCategory', () {
    test('fromString returns matching value', () {
      expect(ReportCategory.fromString('pothole'), ReportCategory.pothole);
      expect(ReportCategory.fromString('rubbish'), ReportCategory.rubbish);
    });

    test('fromString falls back to other for unknown input', () {
      expect(ReportCategory.fromString('lighting'), ReportCategory.other);
    });
  });

  group('ReportStatus', () {
    test('fromString returns matching value', () {
      expect(ReportStatus.fromString('assigned'), ReportStatus.assigned);
      expect(ReportStatus.fromString('underWork'), ReportStatus.underWork);
    });

    test('fromString falls back to reported for unknown input', () {
      expect(ReportStatus.fromString('unknown'), ReportStatus.reported);
    });
  });

  group('DeletionRequestStatus', () {
    test('fromString parses valid names', () {
      expect(
        DeletionRequestStatus.fromString('approved'),
        DeletionRequestStatus.approved,
      );
      expect(
        DeletionRequestStatus.fromString('rejected'),
        DeletionRequestStatus.rejected,
      );
    });

    test('fromString falls back to pending for unknown values', () {
      expect(
        DeletionRequestStatus.fromString('unexpected'),
        DeletionRequestStatus.pending,
      );
    });
  });
}
