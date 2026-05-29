enum AppAuthState { authenticated, unauthenticated, loading, error}

enum UserRole { guest, citizen, worker, company, council, admin }

enum ReportCategory {
	pothole,
	rubbish,
	other;

	static ReportCategory fromString(String value) {
		return ReportCategory.values.firstWhere(
			(category) => category.name == value,
			orElse: () => ReportCategory.other,
		);
	}
}

enum ReportStatus {
	reported,
	assigned,
	underReview,
	underWork,
	repaired;

	static ReportStatus fromString(String value) {
		return ReportStatus.values.firstWhere(
			(status) => status.name == value,
			orElse: () => ReportStatus.reported,
		);
	}
}
