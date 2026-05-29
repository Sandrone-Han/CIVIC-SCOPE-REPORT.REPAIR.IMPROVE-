class Company {
  const Company({
    required this.id,
    required this.name,
    required this.contactEmail,
    required this.specialization,
    required this.workers,
  });

  final String id;
  final String name;
  final String contactEmail;
  final String specialization;
  final List<String> workers;

  factory Company.fromMap(Map<String, dynamic> json) {
    List<String> workers = (json["workers"] as List<String>? ?? []).toList();

    return Company(
      id: json['id'] as String,
      name: json['name'] as String,
      contactEmail: json['contactEmail'] as String,
      specialization: json['specialization'] as String,
      workers: workers,
    );
  }

  static Map<String, dynamic> toJson(Company company) {
    return {
      'id': company.id,
      'name': company.name,
      'contactEmail': company.contactEmail,
      'specialization': company.specialization,
      'workers': company.workers,
    };
  }
}
