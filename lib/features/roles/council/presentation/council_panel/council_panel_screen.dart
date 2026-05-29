import 'package:civic_scope/features/roles/council/presentation/assign_jobs/assign_jobs_screen.dart';
import 'package:civic_scope/features/roles/council/presentation/available_companies/available_companies_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/routing/app_routes.dart';

class CouncilPanelScreen extends StatefulWidget {
	const CouncilPanelScreen({super.key});

	@override
	State<CouncilPanelScreen> createState() => _CouncilPanelScreenState();
}

class _CouncilPanelScreenState extends State<CouncilPanelScreen>
		with SingleTickerProviderStateMixin {
	late final TabController _tabController;

	@override
	void initState() {
		super.initState();
		_tabController = TabController(length: 2, vsync: this);
	}

	@override
	void dispose() {
		_tabController.dispose();
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
					'Council Panel',
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
								Tab(icon: Icon(Icons.assignment_outlined), text: 'Assign Jobs'),
								Tab(icon: Icon(Icons.business_outlined), text: 'Companies'),
							],
						),
					),
				),
			),
			body: TabBarView(
				controller: _tabController,
				children: const [AssignJobsScreen(), AvailableCompaniesScreen()],
			),
			floatingActionButton: FloatingActionButton.extended(
				onPressed: () => context.push(AppRoutes.councilRegisterCompany),
				icon: const Icon(Icons.add_business_outlined),
				label: const Text('Register Company'),
			),
		);
	}
}
