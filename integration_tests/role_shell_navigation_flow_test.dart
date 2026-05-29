import 'package:civic_scope/core/routing/app_routes.dart';
import 'package:civic_scope/features/roles/admin/presentation/admin_scaffold.dart';
import 'package:civic_scope/features/roles/citizen/presentation/citizen_scaffold.dart';
import 'package:civic_scope/features/roles/company/presentation/company_scaffold.dart';
import 'package:civic_scope/features/roles/council/council_scaffold.dart';
import 'package:civic_scope/features/roles/guest/presentation/guest_scaffold.dart';
import 'package:civic_scope/features/roles/worker/presentation/worker_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';

import '../test/helpers/test_app.dart';
import '../test/helpers/test_preferences.dart';

class _ShellConfig {
  const _ShellConfig({
    required this.name,
    required this.builder,
    required this.tabs,
  });

  final String name;
  final Widget Function(StatefulNavigationShell shell) builder;
  final List<_ShellTab> tabs;
}

class _ShellTab {
  const _ShellTab({
    required this.path,
    required this.label,
    required this.pageText,
  });

  final String path;
  final String label;
  final String pageText;
}

Widget _placeholderPage(String text) {
  return Scaffold(
    body: Center(child: Text(text)),
  );
}

GoRouter _routerFor(
  _ShellConfig config, {
  String? initialLocation,
}) {
  return GoRouter(
    initialLocation: initialLocation ?? config.tabs.first.path,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            config.builder(navigationShell),
        branches: [
          for (final tab in config.tabs)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: tab.path,
                  builder: (_, __) => _placeholderPage(tab.pageText),
                ),
              ],
            ),
        ],
      ),
    ],
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final cases = <_ShellConfig>[
    _ShellConfig(
      name: 'guest',
      builder: (shell) => GuestScaffold(navigationShell: shell),
      tabs: const [
        _ShellTab(
          path: AppRoutes.homeMap,
          label: 'Map',
          pageText: 'Guest Map',
        ),
        _ShellTab(
          path: AppRoutes.searchReports,
          label: 'Search',
          pageText: 'Guest Search',
        ),
        _ShellTab(
          path: AppRoutes.settings,
          label: 'Settings',
          pageText: 'Guest Settings',
        ),
      ],
    ),
    _ShellConfig(
      name: 'citizen',
      builder: (shell) => CitizenScaffold(navigationShell: shell),
      tabs: const [
        _ShellTab(path: '/citizen/map', label: 'Map', pageText: 'Citizen Map'),
        _ShellTab(
          path: '/citizen/search',
          label: 'Search',
          pageText: 'Citizen Search',
        ),
        _ShellTab(
          path: '/citizen/report',
          label: 'Report',
          pageText: 'Citizen Report',
        ),
        _ShellTab(
          path: '/citizen/bookmarks',
          label: 'Bookmarked',
          pageText: 'Citizen Bookmarked',
        ),
        _ShellTab(
          path: '/citizen/settings',
          label: 'Settings',
          pageText: 'Citizen Settings',
        ),
      ],
    ),
    _ShellConfig(
      name: 'worker',
      builder: (shell) => WorkerScaffold(navigationShell: shell),
      tabs: const [
        _ShellTab(path: '/worker/map', label: 'Map', pageText: 'Worker Map'),
        _ShellTab(
          path: '/worker/search',
          label: 'Search',
          pageText: 'Worker Search',
        ),
        _ShellTab(path: '/worker/jobs', label: 'Jobs', pageText: 'Worker Jobs'),
        _ShellTab(
          path: '/worker/report',
          label: 'Report',
          pageText: 'Worker Report',
        ),
        _ShellTab(
          path: '/worker/settings',
          label: 'Settings',
          pageText: 'Worker Settings',
        ),
      ],
    ),
    _ShellConfig(
      name: 'company',
      builder: (shell) => CompanyScaffold(navigationShell: shell),
      tabs: const [
        _ShellTab(path: '/company/map', label: 'Map', pageText: 'Company Map'),
        _ShellTab(
          path: '/company/search',
          label: 'Search',
          pageText: 'Company Search',
        ),
        _ShellTab(
          path: '/company/delegate',
          label: 'Delegate',
          pageText: 'Company Delegate',
        ),
        _ShellTab(
          path: '/company/report',
          label: 'Report',
          pageText: 'Company Report',
        ),
        _ShellTab(
          path: '/company/settings',
          label: 'Settings',
          pageText: 'Company Settings',
        ),
      ],
    ),
    _ShellConfig(
      name: 'council',
      builder: (shell) => CouncilScaffold(navigationShell: shell),
      tabs: const [
        _ShellTab(path: '/council/map', label: 'Map', pageText: 'Council Map'),
        _ShellTab(
          path: '/council/search',
          label: 'Search',
          pageText: 'Council Search',
        ),
        _ShellTab(
          path: '/council/delegate',
          label: 'Delegate',
          pageText: 'Council Delegate',
        ),
        _ShellTab(
          path: '/council/report',
          label: 'Report',
          pageText: 'Council Report',
        ),
        _ShellTab(
          path: '/council/settings',
          label: 'Settings',
          pageText: 'Council Settings',
        ),
      ],
    ),
    _ShellConfig(
      name: 'admin',
      builder: (shell) => AdminScaffold(navigationShell: shell),
      tabs: const [
        _ShellTab(path: '/admin/map', label: 'Map', pageText: 'Admin Map'),
        _ShellTab(
          path: '/admin/search',
          label: 'Search',
          pageText: 'Admin Search',
        ),
        _ShellTab(
          path: '/admin/panel',
          label: 'Admin',
          pageText: 'Admin Panel',
        ),
        _ShellTab(
          path: '/admin/report',
          label: 'Report',
          pageText: 'Admin Report',
        ),
        _ShellTab(
          path: '/admin/settings',
          label: 'Settings',
          pageText: 'Admin Settings',
        ),
      ],
    ),
  ];

  for (final config in cases) {
    testWidgets('${config.name} shell shows all tabs and switches branches', (
      tester,
    ) async {
      final prefs = await setUpTestPrefs();
      final router = _routerFor(config);

      await tester.pumpWidget(
        buildRouterApp(
          router: router,
          prefs: prefs,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(config.tabs.first.pageText), findsOneWidget);
      for (final tab in config.tabs) {
        expect(find.text(tab.label), findsWidgets);
      }

      final targetTab = config.tabs[1];
      await tester.tap(find.text(targetTab.label).last);
      await tester.pumpAndSettle();
      expect(find.text(targetTab.pageText), findsOneWidget);

      final finalTab = config.tabs.last;
      await tester.tap(find.text(finalTab.label).last);
      await tester.pumpAndSettle();
      expect(find.text(finalTab.pageText), findsOneWidget);
    });

    testWidgets('${config.name} shell opens correct branch from deep link', (
      tester,
    ) async {
      final prefs = await setUpTestPrefs();
      final targetTab = config.tabs.last;
      final router = _routerFor(
        config,
        initialLocation: targetTab.path,
      );

      await tester.pumpWidget(
        buildRouterApp(
          router: router,
          prefs: prefs,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(targetTab.pageText), findsOneWidget);
      for (final tab in config.tabs) {
        expect(find.text(tab.label), findsWidgets);
      }
    });

    testWidgets('${config.name} shell tolerates tapping current tab again', (
      tester,
    ) async {
      final prefs = await setUpTestPrefs();
      final router = _routerFor(config);

      await tester.pumpWidget(
        buildRouterApp(
          router: router,
          prefs: prefs,
        ),
      );
      await tester.pumpAndSettle();

      final firstTab = config.tabs.first;

      expect(find.text(firstTab.pageText), findsOneWidget);

      await tester.tap(find.text(firstTab.label).last);
      await tester.pumpAndSettle();

      expect(find.text(firstTab.pageText), findsOneWidget);
    });
  }
}