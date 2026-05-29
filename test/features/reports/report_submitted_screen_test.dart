import 'package:civic_scope/core/routing/app_routes.dart';
import 'package:civic_scope/features/reports/presentation/report_submitted_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/test_app.dart';
import '../../helpers/test_preferences.dart';

void main() {
  testWidgets('stores last_screen and displays report details', (tester) async {
    final prefs = await setUpTestPrefs();

    await tester.pumpWidget(
      buildProviderApp(
        prefs: prefs,
        child: const ReportSubmittedScreen(
          reportCategory: 'Pothole',
          reportStatus: 'Reported',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Thank You!'), findsOneWidget);
    expect(find.text('Category: Pothole'), findsOneWidget);
    expect(find.text('Status: Reported'), findsOneWidget);
    expect(prefs.getString('last_screen'), 'report_submitted');
  });

  testWidgets('Go to Home button navigates to the home route', (tester) async {
    final prefs = await setUpTestPrefs();
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const ReportSubmittedScreen(
            reportCategory: 'Pothole',
            reportStatus: 'Reported',
          ),
        ),
        GoRoute(
          path: AppRoutes.homeMap,
          builder: (_, _) => const Scaffold(body: Text('Home map route')),
        ),
      ],
    );

    await tester.pumpWidget(buildRouterApp(router: router, prefs: prefs));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Go to Home'));
    await tester.pumpAndSettle();

    expect(find.text('Home map route'), findsOneWidget);
  });
}
