import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_theme.dart';
import 'package:fera_metalurgica_app/core/widgets/app_bottom_nav_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pump_themed.dart';

const List<AppNavItem> _itens = [
  (
    icone: CupertinoIcons.house,
    iconeAtivo: CupertinoIcons.house_fill,
    label: 'Início',
  ),
  (
    icone: CupertinoIcons.doc_text,
    iconeAtivo: CupertinoIcons.doc_text_fill,
    label: 'Orçamentos',
  ),
  (
    icone: CupertinoIcons.calendar_circle,
    iconeAtivo: CupertinoIcons.calendar_circle_fill,
    label: 'Agenda',
  ),
  (
    icone: CupertinoIcons.ellipsis_circle,
    iconeAtivo: CupertinoIcons.ellipsis_circle_fill,
    label: 'Mais',
  ),
];

void main() {
  testWidgets('informa o índice tocado, inclusive o da aba ativa', (
    tester,
  ) async {
    final tocados = <int>[];
    await pumpThemed(
      tester,
      AppBottomNavBar(
        itens: _itens,
        indiceAtual: 0,
        onSelecionado: tocados.add,
      ),
    );

    await tester.tap(find.text('Mais'));
    await tester.tap(find.text('Início'));
    expect(tocados, [3, 0]);
  });

  testWidgets('ativa preenchida na cor de destaque; inativas em contorno', (
    tester,
  ) async {
    await pumpThemed(
      tester,
      AppBottomNavBar(itens: _itens, indiceAtual: 1, onSelecionado: (_) {}),
    );
    const colors = AppColors.light;

    final ativa = tester.widget<Icon>(
      find.byIcon(CupertinoIcons.doc_text_fill),
    );
    expect(ativa.color, colors.navActive);
    expect(find.byIcon(CupertinoIcons.doc_text), findsNothing);
    final inativa = tester.widget<Icon>(find.byIcon(CupertinoIcons.house));
    expect(inativa.color, colors.navInactive);
    expect(find.byIcon(CupertinoIcons.house_fill), findsNothing);
  });

  testWidgets('sem ripple do Material e com o estado selecionado', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpThemed(
      tester,
      AppBottomNavBar(itens: _itens, indiceAtual: 2, onSelecionado: (_) {}),
    );

    expect(find.byType(InkWell), findsNothing);
    expect(
      tester.getSemantics(find.text('Agenda')),
      matchesSemantics(
        label: 'Agenda',
        isButton: true,
        hasSelectedState: true,
        isSelected: true,
        hasTapAction: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('abas com largura igual, 49 dp de altura e toque na fatia toda', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(320, 640)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    int? tocado;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: const SizedBox.expand(key: ValueKey('corpo')),
          bottomNavigationBar: AppBottomNavBar(
            itens: _itens,
            indiceAtual: 1,
            onSelecionado: (i) => tocado = i,
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(AppBottomNavBar)).height, 49);
    final barra = tester.getRect(find.byType(AppBottomNavBar));
    // Canto da última fatia, longe do ícone e do rótulo.
    await tester.tapAt(Offset(barra.right - 2, barra.top + 4));
    expect(tocado, 3);
  });
}
