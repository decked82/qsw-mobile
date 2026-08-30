import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qsw_mobile/features/home/presentation/pages/home_page.dart';
import 'package:qsw_mobile/features/parts/domain/use_cases/delete_part.dart';
import 'package:qsw_mobile/features/parts/domain/use_cases/get_parts.dart';
import 'package:qsw_mobile/features/parts/presentation/pages/parts_page.dart';

import '../../../parts/domain/repositories/fake_part_repository.dart';

void main() {
  testWidgets('opens PartsPage when Inventory is tapped', (tester) async {
    final repository = FakePartRepository();
    final getParts = GetParts(repository);
    final deletePart = DeletePart(repository);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(800, 900)),
        child: MaterialApp(
          home: const HomePage(),
          onGenerateRoute: (settings) {
            if (settings.name == '/parts') {
              return MaterialPageRoute<void>(
                builder: (_) =>
                    PartsPage(getParts: getParts, deletePart: deletePart),
                settings: settings,
              );
            }

            return MaterialPageRoute<void>(
              builder: (_) => const HomePage(),
              settings: settings,
            );
          },
        ),
      ),
    );

    expect(find.text('QSW Mobile'), findsOneWidget);

    final inventoryButton = find.byKey(const Key('inventory_button'));

    expect(inventoryButton, findsOneWidget);

    await tester.ensureVisible(inventoryButton);
    await tester.pumpAndSettle();

    await tester.tap(inventoryButton);
    await tester.pumpAndSettle();

    expect(find.byType(PartsPage), findsOneWidget);
    expect(find.text('Parts'), findsOneWidget);
  });
}
