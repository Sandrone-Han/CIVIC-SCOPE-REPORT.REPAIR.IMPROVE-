import 'package:civic_scope/features/roles/council/data/register_company/register_company_repository.dart';
import 'package:civic_scope/shared/models/company_model.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class RegisterCompanyScreen extends StatefulWidget {
  const RegisterCompanyScreen({super.key});

  @override
  State<RegisterCompanyScreen> createState() => _RegisterCompanyScreenState();
}

class _RegisterCompanyScreenState extends State<RegisterCompanyScreen>
    with SingleTickerProviderStateMixin {
  final _repository = RegisterCompanyRepository();
  final _uuid = const Uuid();

  late final TabController _tabController;

  final _companyFormKey = GlobalKey<FormState>();
  final _repFormKey = GlobalKey<FormState>();

  final _companyNameController = TextEditingController();
  final _companyEmailController = TextEditingController();
  final _companySpecializationController = TextEditingController();

	final _repEmailController = TextEditingController();
	String? _selectedCompanyId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

	@override
	void dispose() {
		_tabController.dispose();
		_companyNameController.dispose();
		_companyEmailController.dispose();
		_companySpecializationController.dispose();
		_repEmailController.dispose();
		super.dispose();
	}

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 74,
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        iconTheme: IconThemeData(color: scheme.onPrimary),
        title: const Text(
          'Register Company',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: false,
        leadingWidth: 40,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Material(
            color: scheme.surface,
            child: TabBar(
              controller: _tabController,
              labelColor: scheme.primary,
              unselectedLabelColor: scheme.onSurfaceVariant,
              indicatorColor: scheme.primary,
              tabs: const [
                Tab(text: 'Register Company'),
                Tab(text: 'Register Representative'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildCompanyTab(context), _buildRepresentativeTab(context)],
      ),
    );
  }

  Widget _buildCompanyTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _companyFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _companyNameController,
              decoration: const InputDecoration(
                labelText: 'Company Name',
                prefixIcon: Icon(Icons.business_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Company name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _companyEmailController,
              decoration: const InputDecoration(
                labelText: 'Contact Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Contact email is required';
                }
                if (!value.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _companySpecializationController,
              decoration: const InputDecoration(
                labelText: 'Specialization',
                prefixIcon: Icon(Icons.construction_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Specialization is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _registerCompany,
                child: const Text('Create Company'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRepresentativeTab(BuildContext context) {
    return FutureBuilder<List<Company>>(
      future: _repository.getRegisteredCompanies(),
      builder: (context, snapshot) {
        final companies = snapshot.data ?? const <Company>[];

				return SingleChildScrollView(
					padding: const EdgeInsets.all(16),
					child: Form(
						key: _repFormKey,
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								TextFormField(
									controller: _repEmailController,
									decoration: const InputDecoration(
										labelText: 'Representative Email',
										prefixIcon: Icon(Icons.alternate_email_outlined),
									),
									validator: (value) {
										if (value == null || value.trim().isEmpty) {
											return 'Email is required';
										}
										if (!value.contains('@')) return 'Enter a valid email';
										return null;
									},
								),
								const SizedBox(height: 12),
								DropdownButtonFormField<String>(
									value: _selectedCompanyId,
									decoration: const InputDecoration(
										labelText: 'Select Company',
										prefixIcon: Icon(Icons.business_outlined),
									),
									items: companies
										.map((company) => DropdownMenuItem(
											value: company.id,
											child: Text(company.name),
										))
										.toList(),
									onChanged: (String? companyId) {
										setState(() {
											_selectedCompanyId = companyId;
										});
									},
									validator: (value) {
										if (value == null || value.isEmpty) {
											return 'Please select a company';
										}
										return null;
									},
								),
								const SizedBox(height: 20),
								SizedBox(
									width: double.infinity,
									child: FilledButton(
										onPressed: _registerRepresentative,
										child: const Text('Create Representative'),
									),
								),
							],
						),
					),
				);
			},
		);
	}

  Future<void> _registerCompany() async {
    FocusScope.of(context).unfocus();
    if (!_companyFormKey.currentState!.validate()) return;

    final company = Company(
      id: _uuid.v4(),
      name: _companyNameController.text.trim(),
      contactEmail: _companyEmailController.text.trim(),
      specialization: _companySpecializationController.text.trim(),
      workers: [],
    );

    await _repository.registerCompany(company);
    if (!mounted) return;

    _companyNameController.clear();
    _companyEmailController.clear();
    _companySpecializationController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Company ${company.name} registered successfully.'),
      ),
    );
  }

  Future<void> _registerRepresentative() async {
    FocusScope.of(context).unfocus();
    if (!_repFormKey.currentState!.validate()) return;

		await _repository.registerCompanyRepresentative(
      _repEmailController.text.trim(),
      _selectedCompanyId!,
    );
    
		if (!mounted) return;

		_repEmailController.clear();
		setState(() {
			_selectedCompanyId = null;
		});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Company representative registered.')),
    );
  }
}
