
import 'package:cloud_firestore/cloud_firestore.dart';

// DeletionRequestStatus — tracks the lifecycle of a deletion request.
enum DeletionRequestStatus {
  pending,
  approved,
  rejected;

  static DeletionRequestStatus fromString(String value) {
    return DeletionRequestStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DeletionRequestStatus.pending,
    );
  }
}


class DeletionRequest {
  final String id;
  final String reportId;
  final List<String> requestedByIds;
  final List<String> reasons;
  final DateTime createdAt;
  final DeletionRequestStatus status;

  const DeletionRequest({
    required this.id,
    required this.reportId,
    required this.requestedByIds,
    required this.reasons,
    required this.createdAt,
    this.status = DeletionRequestStatus.pending,
  });

  factory DeletionRequest.fromJson(Map<String, dynamic> json) {
    return DeletionRequest(
      id: json['id'] as String,
      reportId: json['reportId'] as String,
      requestedByIds: List<String>.from(json['requestedByIds'] as List),
      reasons: List<String>.from(json['reasons'] as List),
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: DeletionRequestStatus.fromString(
        json['status'] as String? ?? 'pending',
      ),
    );
  }

  factory DeletionRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DeletionRequest(
      id: doc.id,
      reportId: data['reportId'] as String,
      requestedByIds: List<String>.from(
        (data['requestedByIds'] as List<dynamic>? ?? const []),
      ),
      reasons: List<String>.from((data['reasons'] as List<dynamic>? ?? const [])),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: DeletionRequestStatus.fromString(
        data['status'] as String? ?? 'pending',
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reportId': reportId,
      'requestedByIds': requestedByIds,
      'reasons': reasons,
      'createdAt': createdAt.toIso8601String(),
      'status': status.name,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'reportId': reportId,
      'requestedByIds': requestedByIds,
      'reasons': reasons,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status.name,
    };
  }

  DeletionRequest copyWith({
    String? id,
    String? reportId,
    List<String>? requestedByIds,
    List<String>? reasons,
    DateTime? createdAt,
    DeletionRequestStatus? status,
  }) {
    return DeletionRequest(
      id: id ?? this.id,
      reportId: reportId ?? this.reportId,
      requestedByIds: requestedByIds ?? this.requestedByIds,
      reasons: reasons ?? this.reasons,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }

  @override
  String toString() {
    return 'DeletionRequest(id: $id, reportId: $reportId, '
        'requestedByIds: $requestedByIds, reasons: $reasons, '
        'createdAt: $createdAt, status: ${status.name})';
  }

  /// Two requests are equal if they share the same [id].
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeletionRequest && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}