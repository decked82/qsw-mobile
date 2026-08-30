import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qsw_mobile/features/parts/domain/entities/part.dart';
import 'package:qsw_mobile/features/parts/domain/use_cases/search_parts.dart';
import 'package:qsw_mobile/features/parts/presentation/pages/part_search_page.dart';

import '../../domain/repositories/fake_part_repository.dart';

void main() {
  late FakePartRepository repository;
  late SearchParts searchParts;

  setUp(() {
    repository = FakePartRepository();
    searchParts = SearchParts(repository);
  });

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(home: PartSearchPage(searchParts: searchParts)),
    );

    await tester.pumpAndSettle();
  }

  Future<void> addTestParts() async {
    await repository.addPart(
      const Part(
        partCode: 'TEST-001',
        name: 'Brake Pad',
        specification: 'Front',
        barcode: '111111',
        unit: 'EA',
      ),
    );

    await repository.addPart(
      const Part(
        partCode: 'TEST-002',
        name: 'Oil Filter',
        specification: 'Engine',
        barcode: '222222',
        unit: 'EA',
      ),
    );

    await repository.addPart(
      const Part(
        partCode: 'ABC-100',
        name: 'Air Filter',
        specification: 'Cabin',
        barcode: '333333',
        unit: 'EA',
      ),
    );
  }

  testWidgets('shows search form', (tester) async {
    await pumpPage(tester);

    expect(find.byKey(const Key('part_search_field')), findsOneWidget);
    expect(find.byKey(const Key('search_parts_button')), findsOneWidget);
    expect(find.text('Part Search'), findsOneWidget);
    expect(find.text('Enter a part code or name to search.'), findsOneWidget);
  });

  testWidgets('searches parts by part code', (tester) async {
    await addTestParts();
    await pumpPage(tester);

    await tester.enterText(
      find.byKey(const Key('part_search_field')),
      'TEST-001',
    );

    await tester.tap(find.byKey(const Key('search_parts_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('search_results_list')), findsOneWidget);
    expect(find.text('TEST-001'), findsNWidgets(2));
    expect(find.text('Brake Pad'), findsOneWidget);

    expect(find.text('TEST-002'), findsNothing);
    expect(find.text('Air Filter'), findsNothing);
  });

  testWidgets('searches parts by name', (tester) async {
    await addTestParts();
    await pumpPage(tester);

    await tester.enterText(
      find.byKey(const Key('part_search_field')),
      'Filter',
    );

    await tester.tap(find.byKey(const Key('search_parts_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('search_results_list')), findsOneWidget);
    expect(find.text('Oil Filter'), findsOneWidget);
    expect(find.text('Air Filter'), findsOneWidget);

    expect(find.text('Brake Pad'), findsNothing);
  });

  testWidgets('shows no parts found when search has no matches', (
    tester,
  ) async {
    await addTestParts();
    await pumpPage(tester);

    await tester.enterText(
      find.byKey(const Key('part_search_field')),
      'DOES-NOT-EXIST',
    );

    await tester.tap(find.byKey(const Key('search_parts_button')));
    await tester.pumpAndSettle();

    expect(find.text('No parts found'), findsOneWidget);
    expect(find.byKey(const Key('search_results_list')), findsNothing);
  });

  testWidgets('clears search results', (tester) async {
    await addTestParts();
    await pumpPage(tester);

    await tester.enterText(
      find.byKey(const Key('part_search_field')),
      'TEST-001',
    );

    await tester.tap(find.byKey(const Key('search_parts_button')));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const Key('search_results_list')),
        matching: find.text('TEST-001'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('clear_search_button')));
    await tester.pumpAndSettle();

    expect(find.text('Enter a part code or name to search.'), findsOneWidget);
    expect(find.byKey(const Key('search_results_list')), findsNothing);
  });

  testWidgets('does not search when query is empty', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.byKey(const Key('search_parts_button')));
    await tester.pumpAndSettle();

    expect(find.text('Enter a part code or name to search.'), findsOneWidget);
    expect(find.text('No parts found'), findsNothing);
  });
}
