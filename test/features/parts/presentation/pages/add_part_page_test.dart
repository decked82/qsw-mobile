import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qsw_mobile/features/parts/domain/use_cases/add_part.dart';
import 'package:qsw_mobile/features/parts/presentation/pages/add_part_page.dart';

import '../../domain/repositories/fake_part_repository.dart';

void main() {
  testWidgets('adds a part through the form', (tester) async {
    final repository = FakePartRepository();
    final addPart = AddPart(repository);

    await tester.pumpWidget(MaterialApp(home: AddPartPage(addPart: addPart)));

    expect(find.byKey(const Key('add_part_button')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('part_code_field')),
      'TEST-001',
    );

    await tester.enterText(find.byKey(const Key('name_field')), 'Test Part');

    await tester.enterText(
      find.byKey(const Key('specification_field')),
      'Test specification',
    );

    await tester.enterText(find.byKey(const Key('barcode_field')), '123456789');

    await tester.enterText(find.byKey(const Key('unit_field')), 'EA');

    await tester.tap(find.byKey(const Key('add_part_button')));

    await tester.pumpAndSettle();

    final parts = await repository.getParts();

    expect(parts, hasLength(1));
    expect(parts.first.partCode, 'TEST-001');
    expect(parts.first.name, 'Test Part');
    expect(parts.first.specification, 'Test specification');
    expect(parts.first.barcode, '123456789');
    expect(parts.first.unit, 'EA');

    expect(find.text('Part added successfully'), findsOneWidget);
  });
}
