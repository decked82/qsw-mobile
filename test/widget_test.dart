import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qsw_mobile/app.dart';

void main() {
  testWidgets('QSW home page is displayed', (WidgetTester tester) async {
    await tester.pumpWidget(const QswApp(locale: Locale('en')));

    expect(find.text('QSW Mobile'), findsOneWidget);
    expect(find.text('Quick Search in Warehouse'), findsOneWidget);

    expect(find.text('Receiving'), findsOneWidget);
    expect(find.text('Shipping'), findsOneWidget);
    expect(find.text('Part Search'), findsOneWidget);
    expect(find.text('Inventory'), findsOneWidget);
  });
}
