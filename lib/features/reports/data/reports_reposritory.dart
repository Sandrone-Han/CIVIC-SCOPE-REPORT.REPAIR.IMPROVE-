import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:civic_scope/shared/models/report_model.dart';
import 'package:civic_scope/shared/models/report_interaction_model.dart';

class ReportsRepository {
  final _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _reportsCollection =>
      _firestore.collection('reports');

  CollectionReference<Map<String, dynamic>> get _interactionsCollection =>
      _firestore.collection('report_interactions');

  Future<void> submitReport(Report report) async {
    await _reportsCollection.doc(report.id).set(report.toJson());
  }

  Future<List<Report>> getReports() async {
    final snapshot = await _reportsCollection.get();

    if (snapshot.docs.isEmpty) return [];

    return snapshot.docs.map((doc) => Report.fromMap(doc.data())).toList();
  }

  Future<void> submitInteraction(ReportInteraction interaction) async {
    await _interactionsCollection
        .doc(interaction.reportID)
        .set(interaction.toMap());
  }

  Future<ReportInteraction?> getInteraction(String reportID) async {
    final doc = await _interactionsCollection.doc(reportID).get();

    if (!doc.exists) return null;

    return ReportInteraction.fromMap(doc.data()!);
  }

  Future<Map<String, ReportInteraction>> getInteractionsByReportId() async {
    final snapshot = await _interactionsCollection.get();

    final interactions = <String, ReportInteraction>{};
    for (final doc in snapshot.docs) {
      final interaction = ReportInteraction.fromMap(doc.data());
      interactions[interaction.reportID] = interaction;
    }

    return interactions;
  }

  Future<void> updateInteraction(ReportInteraction interaction) async {
    await _interactionsCollection
        .doc(interaction.reportID)
        .update(interaction.toMap());
  }

  Future<void> incrementUpvote({
    required String reportId,
    required bool increase,
  }) async {
    await _interactionsCollection.doc(reportId).update({
      'modified': DateTime.now(),
      'upvotes': FieldValue.increment(increase ? 1 : -1),
    });
  }

  Future<void> addComment({
    required String reportId,
    required Comment comment,
  }) async {
    await _interactionsCollection.doc(reportId).update({
      'modified': DateTime.now(),
      'comments': FieldValue.arrayUnion([comment.toMap()]),
    });
  }
}
