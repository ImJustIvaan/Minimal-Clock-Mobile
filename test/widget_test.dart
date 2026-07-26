import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:minimal_clock/main.dart';

void main() {
  testWidgets('App builds and shows the clock tab', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MinimumClockApp()));
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
