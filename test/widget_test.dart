import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:henhaven_dash/app.dart';

void main() {
  testWidgets('App boots to the splash screen without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const HenhavenDashApp());
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
