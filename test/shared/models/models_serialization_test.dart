import 'package:civic_scope/core/utils/constants/enums.dart';
import 'package:civic_scope/features/authentication/domain/user_model.dart' as auth;
import 'package:civic_scope/shared/models/company_model.dart';
import 'package:civic_scope/shared/models/job_assigment_model.dart';
import 'package:civic_scope/shared/models/report_model.dart';
import 'package:civic_scope/shared/models/users_model.dart' as shared;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Report', () {
    test('toMap serializes all fields using expected keys', () {
      final created = DateTime.utc(2026, 3, 20, 10, 30);
      final report = Report(
        'rep-1',
        'Broken streetlight',
        'alice',
        'lighting',
        'Streetlight not working',
        'https://example.com/image.jpg',
        52.4862,
        -1.8904,
        created,
      );

      final map = report.toMap();

      expect(map['id'], 'rep-1');
      expect(map['title'], 'Broken streetlight');
      expect(map['author'], 'alice');
      expect(map['category'], 'lighting');
      expect(map['description'], 'Streetlight not working');
      expect(map['evidenceURL'], 'https://example.com/image.jpg');
      expect(map['latitude'], '52.4862');
      expect(map['longitude'], '-1.8904');
      expect(map['created'], created.toString());
    });

    test('fromJson deserializes into a strongly typed report', () {
      final report = Report.fromJson({
        'id': 'rep-2',
        'title': 'Pothole',
        'author': 'bob',
        'category': 'roads',
        'description': 'Large pothole on main road',
        'evidenceURL': 'https://example.com/pothole.png',
        'latitude': '52.4800',
        'longitude': '-1.9000',
        'created': '2026-03-18T12:00:00.000Z',
      });

      expect(report.id, 'rep-2');
      expect(report.title, 'Pothole');
      expect(report.author, 'bob');
      expect(report.category, 'roads');
      expect(report.description, 'Large pothole on main road');
      expect(report.evidenceURL, 'https://example.com/pothole.png');
      expect(report.lati, 52.48);
      expect(report.long, -1.9);
      expect(report.created, DateTime.parse('2026-03-18T12:00:00.000Z'));
    });
  });

  group('Company', () {
    test('Company.toJson and Company.fromMap round-trip consistently', () {
      final company = Company(
        id: 'comp-1',
        name: 'UrbanFix',
        contactEmail: 'contact@urbanfix.co.uk',
        specialization: 'Road repair',
        workers: const ['worker-1', 'worker-2'],
      );

      final restored = Company.fromMap(Company.toJson(company));

      expect(restored.id, company.id);
      expect(restored.name, company.name);
      expect(restored.contactEmail, company.contactEmail);
      expect(restored.specialization, company.specialization);
      expect(restored.workers, company.workers);
    });
  });

  group('JobAssignment', () {
    test('copyWith updates only specified fields', () {
      const assignment = JobAssignment(
        id: 'job-1',
        reportId: 'rep-1',
        reportTitle: 'Blocked drain',
        priority: 'medium',
        assignedCompanyId: 'comp-1',
      );

      final updated = assignment.copyWith(assignedWorkerId: 'worker-9');

      expect(updated.id, 'job-1');
      expect(updated.reportId, 'rep-1');
      expect(updated.reportTitle, 'Blocked drain');
      expect(updated.priority, 'medium');
      expect(updated.assignedCompanyId, 'comp-1');
      expect(updated.assignedWorkerId, 'worker-9');
    });

    test('fromJson and toJson preserve optional ids', () {
      const assignment = JobAssignment(
        id: 'job-2',
        reportId: 'rep-2',
        reportTitle: 'Damaged sign',
        priority: 'high',
        assignedCompanyId: 'comp-2',
        assignedWorkerId: 'worker-2',
      );

      final restored = JobAssignment.fromJson(assignment.toJson());

      expect(restored.id, assignment.id);
      expect(restored.assignedCompanyId, assignment.assignedCompanyId);
      expect(restored.assignedWorkerId, assignment.assignedWorkerId);
    });
  });

  group('AppUser models', () {
    test('authentication AppUser serializes and round-trips', () {
      final user = auth.AppUser(
        uid: 'u-1',
        email: 'alice@example.com',
        displayName: 'Alice',
        role: UserRole.citizen,
        companyId: null,
      );

      final restored = auth.AppUser.fromMap(user.toMap());

      expect(restored.uid, user.uid);
      expect(restored.email, user.email);
      expect(restored.displayName, user.displayName);
      expect(restored.role, user.role);
      expect(restored.companyId, user.companyId);
    });

    test('shared AppUser copyWith updates selected fields', () {
      final user = shared.AppUser(
        uid: 'u-2',
        email: 'worker@example.com',
        displayName: 'Worker One',
        role: UserRole.worker,
      );

      final updated = user.copyWith(companyId: 'comp-22', role: UserRole.company);

      expect(updated.uid, user.uid);
      expect(updated.email, user.email);
      expect(updated.displayName, user.displayName);
      expect(updated.role, UserRole.company);
      expect(updated.companyId, 'comp-22');
    });
  });
}
