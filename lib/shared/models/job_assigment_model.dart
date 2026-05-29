class JobAssignment {
  const JobAssignment({
    required this.id,
    required this.reportId,
    required this.reportTitle,
    required this.priority,
    this.assignedCompanyId,
    this.assignedWorkerId,
  });

  final String id;
  final String reportId;
  final String reportTitle;
  final String priority;
  final String? assignedCompanyId;
  final String? assignedWorkerId;

  JobAssignment copyWith({
    String? id,
    String? reportId,
    String? reportTitle,
    String? priority,
    String? assignedCompanyId,
    String? assignedWorkerId,
  }) {
    return JobAssignment(
      id: id ?? this.id,
      reportId: reportId ?? this.reportId,
      reportTitle: reportTitle ?? this.reportTitle,
      priority: priority ?? this.priority,
      assignedCompanyId: assignedCompanyId ?? this.assignedCompanyId,
      assignedWorkerId: assignedWorkerId ?? this.assignedWorkerId,
    );
  }

  factory JobAssignment.fromJson(Map<String, dynamic> json) {
    return JobAssignment(
      id: json['id'] as String,
      reportId: json['reportId'] as String,
      reportTitle: json['reportTitle'] as String,
      priority: json['priority'] as String,
      assignedCompanyId: json['assignedCompanyId'] as String?,
      assignedWorkerId: json['assignedWorkerId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reportId': reportId,
      'priority': priority,
      'reportTitle': reportTitle,
      'assignedCompanyId': assignedCompanyId,
      'assignedWorkerId': assignedWorkerId,
    };
  }

  factory JobAssignment.fromMap(Map<String, dynamic> map) {
    return JobAssignment(
      id: map['id'] as String,
      reportId: map['reportId'] as String,
      reportTitle: map['reportTitle'] as String,
      priority: map['priority'] as String,
      assignedCompanyId: map['assignedCompanyId'] as String?,
      assignedWorkerId: map['assignedWorkerId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reportId': reportId,
      'reportTitle': reportTitle,
      'priority': priority,
      'assignedCompanyId': assignedCompanyId,
      'assignedWorkerId': assignedWorkerId,
    };
  }
}
