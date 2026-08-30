import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qsw_mobile/features/parts/domain/entities/part.dart';
import 'package:qsw_mobile/features/parts/domain/use_cases/delete_part.dart';
import 'package:qsw_mobile/features/parts/domain/use_cases/get_parts.dart';
import 'package:qsw_mobile/features/parts/presentation/pages/parts_page.dart';

import '../../domain/repositories/fake_part_repository.dart';

void main() {
  testWidgets('displays parts from repository', (tester) async {
    final repository = FakePartRepository();

    await repository.addPart(
      const Part(
        partCode: 'TEST-001',
        name: 'Test Part',
        specification: 'Test specification',
        barcode: '123456789',
        unit: 'EA',
      ),
    );

    final getParts = GetParts(repository);
    final deletePart = DeletePart(repository);

    await tester.pumpWidget(
      MaterialApp(
        home: PartsPage(getParts: getParts, deletePart: deletePart),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('TEST-001'), findsOneWidget);
    expect(find.text('Test Part'), findsOneWidget);
    expect(find.text('Test specification'), findsOneWidget);
    expect(find.text('Barcode: 123456789'), findsOneWidget);
    expect(find.text('Unit: EA'), findsOneWidget);
  });

  testWidgets('displays empty state when there are no parts', (tester) async {
    final repository = FakePartRepository();

    final getParts = GetParts(repository);
    final deletePart = DeletePart(repository);

    await tester.pumpWidget(
      MaterialApp(
        home: PartsPage(getParts: getParts, deletePart: deletePart),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('No parts found'), findsOneWidget);
    expect(find.text('Add a part to see it here.'), findsOneWidget);
  });

  testWidgets('deletes a part after confirmation', (tester) async {
    final repository = FakePartRepository();

    final addedPart = await repository.addPart(
      const Part(
        partCode: 'TEST-DELETE-001',
        name: 'Part to Delete',
        specification: 'Test specification',
        barcode: '987654321',
        unit: 'EA',
      ),
    );

    final getParts = GetParts(repository);
    final deletePart = DeletePart(repository);

    await tester.pumpWidget(
      MaterialApp(
        home: PartsPage(getParts: getParts, deletePart: deletePart),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('TEST-DELETE-001'), findsOneWidget);

    await tester.tap(find.byKey(Key('delete_part_${addedPart.id}')));

    await tester.pumpAndSettle();

    expect(find.text('Delete Part'), findsOneWidget);
    expect(
      find.text('Are you sure you want to delete "TEST-DELETE-001"?'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('confirm_delete_button')));

    await tester.pumpAndSettle();

    expect(find.text('TEST-DELETE-001'), findsNothing);
    expect(find.text('No parts found'), findsOneWidget);
    expect(find.text('Part deleted successfully'), findsOneWidget);

    final parts = await repository.getParts();

    expect(parts, isEmpty);
  });

  testWidgets('does not delete a part when deletion is cancelled', (
    tester,
  ) async {
    final repository = FakePartRepository();

    final addedPart = await repository.addPart(
      const Part(partCode: 'TEST-CANCEL-001', name: 'Part to Keep', unit: 'EA'),
    );

    final getParts = GetParts(repository);
    final deletePart = DeletePart(repository);

    await tester.pumpWidget(
      MaterialApp(
        home: PartsPage(getParts: getParts, deletePart: deletePart),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byKey(Key('delete_part_${addedPart.id}')));

    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('cancel_delete_button')));

    await tester.pumpAndSettle();

    expect(find.text('TEST-CANCEL-001'), findsOneWidget);

    final parts = await repository.getParts();

    expect(parts, hasLength(1));
    expect(parts.first.partCode, 'TEST-CANCEL-001');
  });
}
