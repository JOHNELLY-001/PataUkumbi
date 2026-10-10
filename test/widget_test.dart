import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:e_venues/main.dart';

void main() {
  testWidgets('App boots to splash', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.text('HAVEN'), findsOneWidget);
    expect(find.byWidgetPredicate((w) => w is Image), findsOneWidget);
  });
}
