import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:civic_scope/features/reports/data/reports_reposritory.dart';
import 'package:civic_scope/features/roles/admin/data/deletion_requests/deletion_requests_repository.dart';
import 'package:civic_scope/core/routing/app_routes.dart';

class AdminPanelScreen extends StatefulWidget {
	const AdminPanelScreen({super.key});

	@override
	State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
	final _reportsRepository = ReportsRepository();
	final _deletionRequestsRepository = DeletionRequestsRepository();

	late Future<_AdminStats> _statsFuture;

	@override
	void initState() {
		super.initState();
		_load();
	}

	void _load() {
		setState(() {
			_statsFuture = _loadStats();
		});
	}

	Future<_AdminStats> _loadStats() async {
		final results = await Future.wait([
			_reportsRepository.getReports(),
			_deletionRequestsRepository.getPendingDeletionRequests(),
		]);

		final reportsCount = (results[0] as List).length;
		final pendingDeletions = (results[1] as List).length;

		return _AdminStats(
			reportsMade: reportsCount,
			pendingDeletions: pendingDeletions,
		);
	}

	@override
	Widget build(BuildContext context) {
		final scheme = Theme.of(context).colorScheme;
		final text = Theme.of(context).textTheme;

		return Scaffold(
			appBar: AppBar(
				backgroundColor: scheme.primary,
				foregroundColor: scheme.onPrimary,
				iconTheme: IconThemeData(color: scheme.onPrimary),
				title: const Text(
					'Admin Panel',
					style: TextStyle(fontWeight: FontWeight.w800),
				),
				centerTitle: false,
				leadingWidth: 40,
				elevation: 0,
				scrolledUnderElevation: 0,
			),
			body: FutureBuilder<_AdminStats>(
				future: _statsFuture,
				builder: (context, snapshot) {
					if (snapshot.connectionState == ConnectionState.waiting) {
						return const Center(child: CircularProgressIndicator());
					}

					if (snapshot.hasError) {
						return Center(
							child: Padding(
								padding: const EdgeInsets.all(16),
								child: Column(
									mainAxisSize: MainAxisSize.min,
									children: [
										Text(
											'Failed to load admin stats.\n${snapshot.error}',
											textAlign: TextAlign.center,
										),
										const SizedBox(height: 10),
										OutlinedButton.icon(
											onPressed: _load,
											icon: const Icon(Icons.refresh),
											label: const Text('Retry'),
										),
									],
								),
							),
						);
					}

					final stats = snapshot.data ?? const _AdminStats();

					return RefreshIndicator(
						onRefresh: () async => _load(),
						child: SingleChildScrollView(
							physics: const AlwaysScrollableScrollPhysics(),
							padding: const EdgeInsets.all(16),
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: [
									Text(
										'Overview',
										style: text.titleMedium?.copyWith(
											fontWeight: FontWeight.w800,
										),
									),
									const SizedBox(height: 10),
									Row(
										children: [
											Expanded(
												child: _StatCard(
													title: 'Reports Made',
													value: '${stats.reportsMade}',
													icon: Icons.description_outlined,
												),
											),
											const SizedBox(width: 10),
											Expanded(
												child: _StatCard(
													title: 'Pending Deletions',
													value: '${stats.pendingDeletions}',
													icon: Icons.delete_sweep_outlined,
												),
											),
										],
									),
									const SizedBox(height: 24),
									Text(
										'Admin Actions',
										style: text.titleMedium?.copyWith(
											fontWeight: FontWeight.w800,
										),
									),
									const SizedBox(height: 10),
									_ActionCard(
										title: 'Accept Deletion Requests',
										subtitle: 'Review and process report deletion requests.',
										icon: Icons.rule_folder_outlined,
										onTap: () =>
												context.push(AppRoutes.adminDeletionRequests),
									),
									const SizedBox(height: 10),
									_ActionCard(
										title: 'Register Company',
										subtitle: 'Add and manage authorised service companies.',
										icon: Icons.business_outlined,
										onTap: () =>
												context.push(AppRoutes.adminRegisterCompanyReps),
									),
								],
							),
						),
					);
				},
			),
		);
	}
}

class _AdminStats {
	const _AdminStats({this.reportsMade = 0, this.pendingDeletions = 0});

	final int reportsMade;
	final int pendingDeletions;

  
}

class _StatCard extends StatelessWidget {
	const _StatCard({
		required this.title,
		required this.value,
		required this.icon,
	});

	final String title;
	final String value;
	final IconData icon;

	@override
	Widget build(BuildContext context) {
		final scheme = Theme.of(context).colorScheme;
		final text = Theme.of(context).textTheme;

		return Container(
			padding: const EdgeInsets.all(14),
			decoration: BoxDecoration(
				color: scheme.surfaceContainerLow,
				borderRadius: BorderRadius.circular(14),
				border: Border.all(color: scheme.outlineVariant),
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Icon(icon, color: scheme.primary),
					const SizedBox(height: 8),
					Text(
						value,
						style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
					),
					const SizedBox(height: 2),
					Text(
						title,
						style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
					),
				],
			),
		);
	}
}

class _ActionCard extends StatelessWidget {
	const _ActionCard({
		required this.title,
		required this.subtitle,
		required this.icon,
		required this.onTap,
	});

	final String title;
	final String subtitle;
	final IconData icon;
	final VoidCallback onTap;

	@override
	Widget build(BuildContext context) {
		final scheme = Theme.of(context).colorScheme;
		final text = Theme.of(context).textTheme;

		return Card(
			margin: EdgeInsets.zero,
			shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
			child: InkWell(
				borderRadius: BorderRadius.circular(14),
				onTap: onTap,
				child: Padding(
					padding: const EdgeInsets.all(14),
					child: Row(
						children: [
							Container(
								width: 44,
								height: 44,
								decoration: BoxDecoration(
									color: scheme.primaryContainer,
									borderRadius: BorderRadius.circular(10),
								),
								child: Icon(icon, color: scheme.primary),
							),
							const SizedBox(width: 12),
							Expanded(
								child: Column(
									crossAxisAlignment: CrossAxisAlignment.start,
									children: [
										Text(
											title,
											style: text.titleSmall?.copyWith(
												fontWeight: FontWeight.w800,
											),
										),
										const SizedBox(height: 2),
										Text(
											subtitle,
											style: text.bodySmall?.copyWith(
												color: scheme.onSurfaceVariant,
											),
										),
									],
								),
							),
							Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
						],
					),
				),
			),
		);
	}
}
