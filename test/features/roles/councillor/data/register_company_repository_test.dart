import 'package:civic_scope/features/roles/council/data/register_company/register_company_repository.dart';
import 'package:civic_scope/shared/models/company_model.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeRegisterCompanyRepository implements RegisterCompanyRepository {
  FakeRegisterCompanyRepository({List<Company>? companies})
      : _companies = List<Company>.from(companies ?? const <Company>[]);

  final List<Company> _companies;
  int registerCompanyCallCount = 0;
  int registerRepresentativeCallCount = 0;
  String? lastRepresentativeEmail;
  String? lastRepresentativeCompanyId;

  @override
  Future<List<Company>> searchCompaniesForCouncil(String council, {String query = ''}) async {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return List<Company>.from(_companies);
    }

    return _companies.where((company) {
      return company.name.toLowerCase().contains(normalized) ||
          company.id.toLowerCase().contains(normalized);
    }).toList();
  }

  @override
  Future<List<Company>> getRegisteredCompanies() async => List<Company>.from(_companies);

  @override
  Future<void> registerCompany(Company company) async {
    registerCompanyCallCount += 1;
    _companies.add(company);
  }

  @override
  Future<void> registerCompanyRepresentative(String workerEmail, String companyId) async {
    registerRepresentativeCallCount += 1;
    lastRepresentativeEmail = workerEmail;
    lastRepresentativeCompanyId = companyId;
  }
}

void main() {
  group('RegisterCompanyRepository search and registration contract', () {
    late FakeRegisterCompanyRepository repository;

    setUp(() {
      repository = FakeRegisterCompanyRepository(
        companies: const [
          Company(
            id: 'comp_001',
            name: 'UrbanFix',
            contactEmail: 'urbanfix@example.com',
            specialization: 'Road repair',
            workers: [],
          ),
          Company(
            id: 'comp_002',
            name: 'BrightPole',
            contactEmail: 'brightpole@example.com',
            specialization: 'Street lighting',
            workers: [],
          ),
        ],
      );
    });

    test('searchCompaniesForCouncil returns all companies when query is empty', () async {
      final results = await repository.searchCompaniesForCouncil('Any Council');

      expect(results.map((company) => company.id), ['comp_001', 'comp_002']);
    });

    test('searchCompaniesForCouncil filters by company name', () async {
      final results = await repository.searchCompaniesForCouncil(
        'Any Council',
        query: 'urban',
      );

      expect(results.single.name, 'UrbanFix');
    });

    test('searchCompaniesForCouncil filters by company id', () async {
      final results = await repository.searchCompaniesForCouncil(
        'Any Council',
        query: 'comp_002',
      );

      expect(results.single.name, 'BrightPole');
    });

    test('registerCompany adds a new company to the data source', () async {
      await repository.registerCompany(
        const Company(
          id: 'comp_003',
          name: 'DrainMasters',
          contactEmail: 'drain@example.com',
          specialization: 'Drainage',
          workers: [],
        ),
      );

      final companies = await repository.getRegisteredCompanies();
      expect(repository.registerCompanyCallCount, 1);
      expect(companies.map((company) => company.id), contains('comp_003'));
    });

    test('registerCompanyRepresentative records the submitted representative details', () async {
      await repository.registerCompanyRepresentative('charlie@example.com', 'comp_001');

      expect(repository.registerRepresentativeCallCount, 1);
      expect(repository.lastRepresentativeEmail, 'charlie@example.com');
      expect(repository.lastRepresentativeCompanyId, 'comp_001');
    });
  });
}
