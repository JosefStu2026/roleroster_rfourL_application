import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roleroster_rfourl_application/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const RoleRosterApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
