import 'package:civic_scope/features/roles/council/data/register_company/register_company_repository.dart';
import 'package:civic_scope/shared/models/company_model.dart';
import 'package:flutter/material.dart';

class AvailableCompaniesScreen extends StatefulWidget {
	const AvailableCompaniesScreen({super.key});

	@override
	State<AvailableCompaniesScreen> createState() =>
			_AvailableCompaniesScreenState();
}

class _AvailableCompaniesScreenState extends State<AvailableCompaniesScreen> {
	final _repository = RegisterCompanyRepository();

	late Future<List<Company>> _companiesFuture;

	@override
	void initState() {
		super.initState();
		_load();
	}

	void _load() {
		setState(() {
			_companiesFuture = _repository.getRegisteredCompanies();
		});
	}

	Future<void> _refresh() {
		return Future.delayed(const Duration(milliseconds: 500)).then((_) {
			_load();
		});
	}

	@override
	Widget build(BuildContext context) {
		final scheme = Theme.of(context).colorScheme;

		return FutureBuilder<List<Company>>(
			future: _companiesFuture,
			builder: (context, snapshot) {
				if (snapshot.connectionState == ConnectionState.waiting) {
					return const Center(child: CircularProgressIndicator());
				}

				if (snapshot.hasError) {
					return Center(
						child: Text(
							'Unable to load companies.\n${snapshot.error}',
							textAlign: TextAlign.center,
						),
					);
				}

				final companies = snapshot.data ?? <Company>[];

				if (companies.isEmpty) {
					return Center(
						child: Column(
							mainAxisSize: MainAxisSize.min,
							children: [
								Icon(
									Icons.business_outlined,
									size: 56,
									color: scheme.onSurfaceVariant,
								),
								const SizedBox(height: 10),
								const Text('No companies registered to this council yet.'),
							],
						),
					);
				}

				return RefreshIndicator(
					onRefresh: _refresh,
					child: ListView.separated(
						padding: const EdgeInsets.all(16),
						itemCount: companies.length + 1,
						separatorBuilder: (_, index) {
							if (index == companies.length - 1) {
								return const SizedBox(height: 10);
							}
							return const SizedBox(height: 10);
						},
						itemBuilder: (context, index) {
							if (index == companies.length) {
								return Padding(
									padding: const EdgeInsets.only(top: 24, bottom: 16),
									child: Column(
										children: [
											Container(
												padding: const EdgeInsets.all(12),
												decoration: BoxDecoration(
													color: scheme.primaryContainer.withAlpha(51),
													borderRadius: BorderRadius.circular(8),
													border: Border.all(
														color: scheme.primary.withAlpha(77),
														width: 1,
													),
												),
												child: Row(
													children: [
														Icon(
															Icons.info_outline,
															size: 20,
															color: scheme.primary,
														),
														const SizedBox(width: 12),
														Expanded(
															child: Column(
																crossAxisAlignment: CrossAxisAlignment.start,
																children: [
																	Text(
																		'Not seeing a registered company?',
																		style: Theme.of(context)
																			.textTheme
																			.labelLarge
																			?.copyWith(color: scheme.primary),
																	),
																	const SizedBox(height: 4),
																	Text(
																		'Pull down to refresh the page.',
																		style: Theme.of(context)
																			.textTheme
																			.bodySmall
																			?.copyWith(color: scheme.onSurfaceVariant),
																	),
																],
															),
														),
													],
												),
											),
										],
									),
								);
							}

							final company = companies[index];
							return Card(
								margin: EdgeInsets.zero,
								child: ListTile(
									leading: CircleAvatar(
										backgroundColor: scheme.primaryContainer,
										child: Icon(
											Icons.business,
											color: scheme.onPrimaryContainer,
										),
									),
									title: Text(company.name),
									subtitle: Text(
										'${company.specialization}\n${company.contactEmail}',
									),
									isThreeLine: true,
								),
							);
						},
					),
				);
			},
		);
	}
}
