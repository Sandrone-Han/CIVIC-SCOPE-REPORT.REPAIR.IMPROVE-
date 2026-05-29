import 'package:civic_scope/core/utils/constants/enums.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:civic_scope/shared/models/job_assigment_model.dart';
import 'package:civic_scope/shared/models/report_interaction_model.dart';
import 'package:civic_scope/shared/models/report_model.dart';

class WorkerRepository {
  final _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _jobsCollection =>
      _firestore.collection('job_assignments');

    CollectionReference<Map<String, dynamic>> get _reportsCollection =>
      _firestore.collection('reports');

  CollectionReference<Map<String, dynamic>> get _reportInteractionsCollection =>
      _firestore.collection('report_interactions');

  Future<List<JobAssignment>> getAssignedJobs(String workerId) async {
    final snapshot = await _jobsCollection
        .where('assignedWorkerId', isEqualTo: workerId)
        .get();
    return snapshot.docs.map((doc) => JobAssignment.fromMap(doc.data())).toList();
  }

  Future<List<JobAssignment>> getActiveAssignedJobs(String workerId) {
    return _getAssignedJobsByCompletion(workerId, isCompleted: false);
  }

  Future<List<JobAssignment>> getCompletedAssignedJobs(String workerId) {
    return _getAssignedJobsByCompletion(workerId, isCompleted: true);
  }

  Future<void> updateJobAssignment(JobAssignment assignment) async {
    await _jobsCollection
        .doc(assignment.reportId)
        .update(assignment.toJson());
  }

  Future<void> updateReportInteractionStatus(String reportId, ReportStatus newStatus) async {
    final interactionRef = _reportInteractionsCollection.doc(reportId);
    await interactionRef.update({'status': newStatus.name});
  }

  Future<List<Report>> getReportsByIds(List<String> reportIds) async {
    if (reportIds.isEmpty) return const <Report>[];

    final reportIdSet = reportIds.toSet();
    final snapshot = await _reportsCollection.get();

    return snapshot.docs
        .map((doc) => Report.fromMap(doc.data()))
        .where((report) => reportIdSet.contains(report.id))
        .toList();
  }

  Future<Map<String, ReportInteraction>> getInteractionsByReportIds(
    List<String> reportIds,
  ) async {
    if (reportIds.isEmpty) return <String, ReportInteraction>{};

    final reportIdSet = reportIds.toSet();
    final snapshot = await _reportInteractionsCollection.get();
    final interactionsById = <String, ReportInteraction>{};

    for (final doc in snapshot.docs) {
      final interaction = ReportInteraction.fromMap(doc.data());
      if (reportIdSet.contains(interaction.reportID)) {
        interactionsById[interaction.reportID] = interaction;
      }
    }

    return interactionsById;
  }

  Future<List<JobAssignment>> _getAssignedJobsByCompletion(
    String workerId, {
    required bool isCompleted,
  }) async {
    final assignments = await getAssignedJobs(workerId);
    if (assignments.isEmpty) return const <JobAssignment>[];

    final reportIds = assignments
        .map((assignment) => assignment.reportId)
        .toSet()
        .toList();
    final interactionsByReportId = await getInteractionsByReportIds(reportIds);

    return assignments.where((assignment) {
      final status =
          interactionsByReportId[assignment.reportId]?.reportStatus ??
          ReportStatus.assigned;
      final completed = status == ReportStatus.repaired;
      return isCompleted ? completed : !completed;
    }).toList();
  }
}