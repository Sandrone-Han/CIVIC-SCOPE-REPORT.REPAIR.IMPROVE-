import 'package:civic_scope/core/utils/constants/enums.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:civic_scope/shared/models/company_model.dart';

class RegisterCompanyRepository {
  Future<List<Company>> getRegisteredCompanies() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('companies')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Company.fromMap({
        'id': data['id'] ?? doc.id,
        'name': data['name'],
        'title': data['title'],
        'contactEmail': data['contactEmail'],
        'specialization': data['specialization'],
      });
    }).toList();
  }

  Future<List<Company>> searchCompaniesForCouncil(
    String council, {
    String query = '',
  }) async {
    final normalized = query.trim().toLowerCase();
    final companies = await getRegisteredCompanies();

    if (normalized.isEmpty) return companies;

    return companies
        .where(
          (company) =>
              company.name.toLowerCase().contains(normalized) ||
              company.id.toLowerCase().contains(normalized),
        )
        .toList();
  }

  Future<void> registerCompany(Company company) async {
    await FirebaseFirestore.instance
        .collection('companies')
        .doc(company.id)
        .set(Company.toJson(company));
  }

  Future<void> registerCompanyRepresentative(
    String workerEmail,
    String companyId,
  ) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: workerEmail)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      throw Exception('No user found with email: $workerEmail');
    }

    final userDoc = querySnapshot.docs.first;
    await userDoc.reference.update({
      'companyId': companyId,
      'role': UserRole.company.name,
    });
  }
}
