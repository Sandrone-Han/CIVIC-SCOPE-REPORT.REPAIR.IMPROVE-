import 'package:civic_scope/features/home_map/presentation/work_in_progress_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('wip screen shows generic placeholder when no feature is provided', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WIPScreen(),
      ),
    );

    expect(find.text('Coming Soon'), findsOneWidget);
    expect(find.text('This feature has not been implemented yet.'), findsOneWidget);
    expect(find.byIcon(Icons.construction_rounded), findsOneWidget);
  });

  testWidgets('wip screen shows feature-specific message when feature name is provided', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WIPScreen('Reports'),
      ),
    );

    expect(find.text('Reports'), findsOneWidget);
    expect(find.text("The 'Reports' feature has not been implemented yet."), findsOneWidget);
  });
}
