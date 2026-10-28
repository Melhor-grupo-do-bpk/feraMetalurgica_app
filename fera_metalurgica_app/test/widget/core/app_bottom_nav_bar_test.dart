import 'package:fera_metalurgica_app/core/theme/app_theme.dart';
import 'package:fera_metalurgica_app/core/widgets/app_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pump_themed.dart';

void main() {
  testWidgets('mostra as abas e informa o índice tocado', (tester) async {
    int? tocado;
    await pumpThemed(
      tester,
      AppBottomNavBar(
        itens: const [
          (icone: Icons.home_outlined, label: 'Início'),
          (icone: Icons.menu, label: 'Mais'),
        ],
        indiceAtual: 0,
        onSelecionado: (i) => tocado = i,
      ),
    );

    expect(find.text('Início'), findsOneWidget);
    await tester.tap(find.text('Mais'));
    expect(tocado, 1);
  });

  testWidgets('em 320 dp não transborda nem ocupa a altura do corpo', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(320, 640)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: const SizedBox.expand(key: ValueKey('corpo')),
          bottomNavigationBar: AppBottomNavBar(
            itens: const [
              (icone: Icons.home_outlined, label: 'Início'),
              (icone: Icons.description_outlined, label: 'Orçamentos'),
              (icone: Icons.inventory_2_outlined, label: 'Catálogo'),
              (icone: Icons.menu, label: 'Mais'),
            ],
            indiceAtual: 1,
            onSelecionado: (_) {},
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(AppBottomNavBar)).height, lessThan(100));
    expect(
      tester.getSize(find.byKey(const ValueKey('corpo'))).height,
      greaterThan(500),
    );
  });
}
