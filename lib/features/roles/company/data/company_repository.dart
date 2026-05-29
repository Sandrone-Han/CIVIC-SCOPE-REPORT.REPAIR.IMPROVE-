import 'package:civic_scope/core/utils/constants/enums.dart';
import 'package:civic_scope/shared/models/report_interaction_model.dart';
import 'package:civic_scope/shared/models/users_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:civic_scope/shared/models/job_assigment_model.dart';

class CompanyRepository {
  final _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _jobsCollection =>
      _firestore.collection('job_assignments');

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _reportInteractionsCollection =>
      _firestore.collection('report_interactions');

  Future<List<JobAssignment>> getAssignedJobs(String companyId) async {
    final snapshot = await _jobsCollection
        .where('assignedCompanyId', isEqualTo: companyId)
        .get();

    return snapshot.docs
        .map((doc) => JobAssignment.fromMap( doc.data() ))
        .toList();
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

  Future<List<AppUser>> getCompanyEmployees(String companyId) async {
    final snapshot = await _usersCollection
        .where('companyId', isEqualTo: companyId)
        .where('role', isEqualTo: UserRole.worker.name)
        .get();

    return snapshot.docs
        .map((doc) => AppUser.fromMap(doc.data()))
        .toList();
  }

  Future<void> addWorkerToCompany(String workerEmail, String companyId) async {
    final querySnapshot = await _usersCollection
        .where('email', isEqualTo: workerEmail)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      throw Exception('No user found with email: $workerEmail');
    }

    final userDoc = querySnapshot.docs.first;
    await userDoc.reference.update({'companyId': companyId, 'role': UserRole.worker.name});
  }


  Future<void> removeWorkerFromCompany(String workerId) async {
    final userDoc = _usersCollection.doc(workerId);
    await userDoc.update({'companyId': null, 'role': UserRole.citizen.name});
  }
}