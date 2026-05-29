import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:civic_scope/features/roles/admin/domain/deletion_requests/deletion_request.dart';
class DeletionRequestsRepository {
  final _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _requestsCollection =>
      _firestore.collection('deletion_requests');

  CollectionReference<Map<String, dynamic>> get _reportsCollection =>
      _firestore.collection('reports');

  CollectionReference<Map<String, dynamic>> get _interactionsCollection =>
      _firestore.collection('report_interactions');

  CollectionReference<Map<String, dynamic>> get _jobsCollection =>
      _firestore.collection('job_assignments');

  /// Returns all deletion requests regardless of status.
  ///
  Future<List<DeletionRequest>> getDeletionRequests() async {
    final snapshot = await _requestsCollection.get();
    final requests = snapshot.docs.map(DeletionRequest.fromFirestore).toList();
    requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return requests;
  }

  /// Create a new deletion request for a given report with specified reasons.
  /// If a request already exists for the same report, it should append the new reasons and requester to the existing request instead of creating a duplicate.
  Future<void> createOrUpdateDeletionRequest({
    required String reportId,
    required String requesterId,
    required List<String> reasons,
  }) async {
    final cleanReasons = reasons
        .map((reason) => reason.trim())
        .where((reason) => reason.isNotEmpty)
        .toList();

    final existingRequests = await _requestsCollection
        .where('reportId', isEqualTo: reportId)
        .where('status', isEqualTo: DeletionRequestStatus.pending.name)
        .limit(1)
        .get();

    if (existingRequests.docs.isNotEmpty) {
      final docRef = existingRequests.docs.first.reference;
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        final data = snapshot.data() ?? <String, dynamic>{};

        final existingRequesters = List<String>.from(
          (data['requestedByIds'] as List<dynamic>? ?? const []),
        );
        final existingReasons = List<String>.from(
          (data['reasons'] as List<dynamic>? ?? const []),
        );

        if (!existingRequesters.contains(requesterId)) {
          existingRequesters.add(requesterId);
        }
        existingReasons.addAll(cleanReasons);

        transaction.update(docRef, {
          'requestedByIds': existingRequesters,
          'reasons': existingReasons,
        });
      });
      return;
    }

    final newRequest = DeletionRequest(
      id: _requestsCollection.doc().id,
      reportId: reportId,
      requestedByIds: [requesterId],
      reasons: cleanReasons,
      createdAt: DateTime.now().toUtc(),
      status: DeletionRequestStatus.pending,
    );

    await _requestsCollection.doc(newRequest.id).set(newRequest.toFirestore());
  }

  /// Returns only [DeletionRequestStatus.pending] requests.
  ///
  Future<List<DeletionRequest>> getPendingDeletionRequests() async {
    final snapshot = await _requestsCollection
        .where('status', isEqualTo: DeletionRequestStatus.pending.name)
        .get();
    final requests = snapshot.docs.map(DeletionRequest.fromFirestore).toList();
    requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return requests;
  }

  /// Fetches a single deletion request by [id]. Returns null if not found.
  ///
  Future<DeletionRequest?> getDeletionRequestById(String id) async {
    final doc = await _requestsCollection.doc(id).get();
    if (!doc.exists) return null;
    return DeletionRequest.fromFirestore(doc);
  }

  /// Approves the deletion request and (in production) deletes the report.
  ///
  Future<void> approveDeletionRequest(String id) async {
    final requestRef = _requestsCollection.doc(id);

    await _firestore.runTransaction((transaction) async {
      final requestSnapshot = await transaction.get(requestRef);
      if (!requestSnapshot.exists) {
        throw StateError('Deletion request not found: $id');
      }

      final requestData = requestSnapshot.data() ?? <String, dynamic>{};
      final reportId = requestData['reportId'] as String?;
      if (reportId == null || reportId.isEmpty) {
        throw StateError('Invalid deletion request payload: missing reportId');
      }

      transaction.update(requestRef, {'status': DeletionRequestStatus.approved.name});
      transaction.delete(_reportsCollection.doc(reportId));
      transaction.delete(_interactionsCollection.doc(reportId));
      transaction.delete(_jobsCollection.doc(reportId));
    });
  }

  /// Rejects the deletion request, leaving the report untouched.
  ///
  Future<void> rejectDeletionRequest(String id) async {
    await _requestsCollection.doc(id).update({
      'status': DeletionRequestStatus.rejected.name,
    });
  }
}
