// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:staapp2025/widgets/homeblocks/homeblocks.dart';

void main() {
  testWidgets('App builds', (WidgetTester tester) async {
    // Build only the AnnouncementsBlock inside a MaterialApp to keep the test
    // focused and avoid unrelated layout/network issues.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: AnnouncementsBlock()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Announcements Board'), findsOneWidget);
    // The fallback announcement should be present when network fails.
    expect(find.text('Titans'), findsOneWidget);
  });
}
