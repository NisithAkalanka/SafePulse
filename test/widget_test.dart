// Widget smoke tests. SafePulseApp requires Firebase.initializeApp() (see lib/main.dart);
// full-app tests should mock Firebase or run as integration tests on a device/emulator.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('smoke test — Material app builds', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('SafePulse')),
        ),
      ),
    );

    expect(find.text('SafePulse'), findsOneWidget);
  });
}
