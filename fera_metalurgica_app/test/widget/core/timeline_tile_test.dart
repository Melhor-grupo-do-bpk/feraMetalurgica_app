import 'package:fera_metalurgica_app/core/widgets/status_chip.dart';
import 'package:fera_metalurgica_app/core/widgets/timeline_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pump_themed.dart';

void main() {
  testWidgets('mostra horário, título, descrição, tag e linha', (tester) async {
    await pumpThemed(
      tester,
      const TimelineTile(
        horario: '09:00',
        titulo: 'Revisar orçamento #00482',
        descricao: 'Cliente: Indústrias Apex S/A',
        tag: StatusChip(label: 'Orçamento', uppercase: true),
      ),
    );

    expect(find.text('09:00'), findsOneWidget);
    expect(find.text('Revisar orçamento #00482'), findsOneWidget);
    expect(find.text('Cliente: Indústrias Apex S/A'), findsOneWidget);
    expect(find.text('ORÇAMENTO'), findsOneWidget);
    expect(find.byKey(const ValueKey('timeline-line')), findsOneWidget);
  });

  testWidgets('tarefa concluída fica riscada, com check e sem tag', (
    tester,
  ) async {
    await pumpThemed(
      tester,
      const TimelineTile(
        horario: '11:30',
        titulo: 'Manutenção preventiva',
        tag: StatusChip(label: 'Produção'),
        concluida: true,
        ultimo: true,
      ),
    );

    final titulo = tester.widget<Text>(find.text('Manutenção preventiva'));
    expect(titulo.style?.decoration, TextDecoration.lineThrough);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    expect(find.text('Produção'), findsNothing);
    expect(find.byKey(const ValueKey('timeline-line')), findsNothing);
  });

  testWidgets('sem onMarcadorPressed, o marcador não é botão', (tester) async {
    await pumpThemed(
      tester,
      const TimelineTile(horario: '09:00', titulo: 'Visita técnica'),
    );

    expect(find.byKey(const ValueKey('timeline-dot')), findsOneWidget);
    expect(find.byType(IconButton), findsNothing);
  });

  testWidgets('com onMarcadorPressed, o marcador é um botão de 48 dp', (
    tester,
  ) async {
    var toques = 0;
    await pumpThemed(
      tester,
      TimelineTile(
        horario: '09:00',
        titulo: 'Visita técnica',
        onMarcadorPressed: () => toques++,
      ),
    );

    final botao = find.byKey(const ValueKey('timeline-marcador'));
    expect(tester.getSize(botao).width, greaterThanOrEqualTo(48));
    expect(tester.getSize(botao).height, greaterThanOrEqualTo(48));
    expect(find.byTooltip('Marcar como concluída'), findsOneWidget);

    await tester.tap(botao);
    expect(toques, 1);
  });

  testWidgets('tarefa concluída oferece marcar como pendente', (tester) async {
    await pumpThemed(
      tester,
      TimelineTile(
        horario: '09:00',
        titulo: 'Visita técnica',
        concluida: true,
        onMarcadorPressed: () {},
      ),
    );

    expect(find.byTooltip('Marcar como pendente'), findsOneWidget);
  });

  group('etiqueta e título (HO-V2-E-03)', () {
    const titulo = 'Produção do portão basculante da obra';

    /// Monta o tile numa linha de [largura] dp, como na agenda.
    Future<void> montar(WidgetTester tester, double largura) async {
      tester.view
        ..physicalSize = Size(largura + 32, 800)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pumpThemed(
        tester,
        const TimelineTile(
          horario: '10:00',
          titulo: titulo,
          tag: StatusChip(label: 'Produção', uppercase: true),
          ultimo: true,
        ),
      );
    }

    testWidgets('num cartão estreito (360 dp), a etiqueta vai para cima', (
      tester,
    ) async {
      // 360 dp de tela menos as margens da agenda: o tile fica com 286.
      await montar(tester, 286);

      final etiqueta = tester.getRect(find.text('PRODUÇÃO'));
      final texto = tester.getRect(find.text(titulo));
      expect(etiqueta.bottom, lessThanOrEqualTo(texto.top));
      // O título usa a largura do cartão inteira, não o que sobra ao lado
      // da etiqueta.
      expect(texto.width, greaterThan(160));
      expect(tester.takeException(), isNull);
    });

    testWidgets('com espaço (tablet), a etiqueta fica ao lado', (tester) async {
      await montar(tester, 700);

      final etiqueta = tester.getRect(find.text('PRODUÇÃO'));
      final texto = tester.getRect(find.text(titulo));
      expect(etiqueta.left, greaterThan(texto.right));
      expect(etiqueta.top, lessThan(texto.bottom));
    });
  });
}
