import 'package:civic_scope/core/utils/constants/enums.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:civic_scope/shared/models/job_assigment_model.dart';
import 'package:civic_scope/shared/models/report_model.dart';
import 'package:civic_scope/shared/models/report_interaction_model.dart';

class AssignJobsRepository {
  final _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _jobsCollection =>
      _firestore.collection('job_assignments');

  CollectionReference<Map<String, dynamic>> get _reportsCollection =>
      _firestore.collection('reports');

  CollectionReference<Map<String, dynamic>> get _interactionsCollection =>
      _firestore.collection('report_interactions');

  Future<void> assignJob(
    ReportInteraction updatedInteraction,
    JobAssignment assignment,
  ) async {
    await _interactionsCollection
        .doc(updatedInteraction.reportID)
        .update(updatedInteraction.toMap());

    await _jobsCollection.doc(assignment.reportId).set(assignment.toJson());
  }

  Future<List<JobAssignment>> getJobAssignments() async {
    final snapshot = await _jobsCollection.get();

    if (snapshot.docs.isEmpty) return [];

    return snapshot.docs
        .map((doc) => JobAssignment.fromMap(doc.data()))
        .toList();
  }

  Future<JobAssignment?> getJobAssignment(String reportId) async {
    final doc = await _jobsCollection.doc(reportId).get();
    if (!doc.exists) return null;
    return JobAssignment.fromMap(doc.data()!);
  }

  Future<List<Report>> getUnAssignedReports() async {
    final snapshot = await _reportsCollection.get();
    final interactionsSnapshot = await _interactionsCollection.get();

    final interactionsMap = {
      for (var doc in interactionsSnapshot.docs)
        doc.id: ReportInteraction.fromMap(doc.data()),
    };

    return snapshot.docs
        .where(
          (doc) =>
              interactionsMap[doc.id]?.reportStatus == ReportStatus.reported,
        )
        .map((doc) => Report.fromMap(doc.data()))
        .toList();
  }
}
