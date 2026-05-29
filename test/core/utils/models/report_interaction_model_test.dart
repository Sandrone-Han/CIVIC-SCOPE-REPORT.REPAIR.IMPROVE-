import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:civic_scope/core/utils/constants/enums.dart';
import 'package:civic_scope/shared/models/report_interaction_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Comment', () {
    test('toMap and fromMap preserve comment fields', () {
      final comment = Comment('alice', 'Needs urgent repair');
      final restored = Comment.fromMap(comment.toMap());

      expect(restored.commentAuthor, 'alice');
      expect(restored.comment, 'Needs urgent repair');
    });

    test('fromMap falls back to empty strings when keys are missing', () {
      final restored = Comment.fromMap(<String, dynamic>{});

      expect(restored.commentAuthor, '');
      expect(restored.comment, '');
    });
  });

  group('ReportInteraction', () {
    test('toMap serializes report interaction and nested comments', () {
      final interaction = ReportInteraction(
        'rep-1',
        ReportStatus.underReview,
        12,
        [Comment('alice', 'Assigned to team'), Comment('bob', 'Thanks')],
        DateTime.utc(2026, 3, 21, 10),
      );

      final map = interaction.toMap();

      expect(map['reportID'], 'rep-1');
      expect(map['status'], ReportStatus.underReview.name);
      expect(map['upvotes'], 12);
      expect(map['comments'], [
        {'commentAuthor': 'alice', 'comment': 'Assigned to team'},
        {'commentAuthor': 'bob', 'comment': 'Thanks'},
      ]);
      expect(map['modified'], interaction.lastModified);
    });

    test('fromMap deserializes timestamp and comments', () {
      final interaction = ReportInteraction.fromMap({
        'reportID': 'rep-2',
        'status': ReportStatus.repaired.name,
        'upvotes': 5,
        'comments': [
          {'commentAuthor': 'charlie', 'comment': 'Fixed'},
        ],
        'modified': Timestamp.fromDate(DateTime.utc(2026, 3, 22, 8, 30)),
      });

      expect(interaction.reportID, 'rep-2');
      expect(interaction.reportStatus, ReportStatus.repaired);
      expect(interaction.upvotes, 5);
      expect(interaction.comments.single.commentAuthor, 'charlie');
      expect(interaction.comments.single.comment, 'Fixed');
      expect(interaction.lastModified.toUtc(), DateTime.utc(2026, 3, 22, 8, 30));
    });

    test('toJson and fromJson round-trip cleanly', () {
      final interaction = ReportInteraction(
        'rep-3',
        ReportStatus.assigned,
        3,
        [Comment('dana', 'Queued for inspection')],
        DateTime.utc(2026, 3, 23, 9, 15),
      );

      final restored = ReportInteraction.fromJson(interaction.toJson());

      expect(restored.reportID, interaction.reportID);
      expect(restored.reportStatus, interaction.reportStatus);
      expect(restored.upvotes, interaction.upvotes);
      expect(restored.comments.single.commentAuthor, 'dana');
      expect(restored.lastModified.toUtc(), interaction.lastModified.toUtc());
    });
  });
}
