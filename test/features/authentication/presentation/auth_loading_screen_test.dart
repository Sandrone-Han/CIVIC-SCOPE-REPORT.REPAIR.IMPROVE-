import 'dart:convert';
import 'dart:typed_data';

import 'package:civic_scope/features/authentication/presentation/auth_loading_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    ServicesBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
      'flutter/assets',
      (ByteData? message) async {
        final key = utf8.decode(message!.buffer.asUint8List());
        if (key == 'assets/civic_scope_banner.svg') {
          const svg =
              '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 10 10"></svg>';
          final bytes = Uint8List.fromList(utf8.encode(svg));
          return ByteData.view(bytes.buffer);
        }
        return null;
      },
    );
  });

  tearDownAll(() {
    ServicesBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
  });

  testWidgets('auth loading screen shows indicator and loading text', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AuthLoadingScreen(),
      ),
    );

    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Loading...'), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });
}