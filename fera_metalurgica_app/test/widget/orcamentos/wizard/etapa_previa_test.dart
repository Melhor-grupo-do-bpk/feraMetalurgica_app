import 'package:fera_metalurgica_app/core/domain/dinheiro.dart';
import 'package:fera_metalurgica_app/features/orcamentos/orcamentos.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/previa/aviso_total_zero.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/previa/previa_orcamento.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../mocks/dados_exemplo.dart';
import '../../core/pump_themed.dart';

/// A prévia comercial (prompt §4, D-39), montada direto com os orçamentos
/// de exemplo, sem providers.
void main() {
  Future<void> montar(
    WidgetTester tester,
    Widget previa, {
    ThemeMode themeMode = ThemeMode.light,
    Size tamanho = const Size(800, 2400),
  }) async {
    tester.view
      ..physicalSize = tamanho
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpThemed(
      tester,
      SingleChildScrollView(child: previa),
      themeMode: themeMode,
    );
  }

  double topo(WidgetTester tester, String texto) =>
      tester.getTopLeft(find.text(texto)).dy;

  testWidgets('exemplo C: cabeçalho, produtos e totais na ordem da D-39', (
    tester,
  ) async {
    await montar(tester, PreviaOrcamento.deOrcamento(orcamentoExemploC));

    expect(find.text('Nº 071023-01'), findsOneWidget);
    expect(find.text('Emissão: 07/10/2023'), findsOneWidget);
    expect(find.text('Válido até 22/10/2023'), findsOneWidget);
    expect(find.text('Fera Metalúrgica Ltda'), findsOneWidget);
    expect(find.text('João da Silva'), findsOneWidget);

    // Produtos: quantidade × preço unitário e o total.
    expect(find.text('Mesa de jantar sob medida'), findsOneWidget);
    expect(find.text(r'2 × R$ 1.353,20'), findsOneWidget);
    expect(find.text(r'R$ 2.706,40'), findsOneWidget);
    expect(find.text(r'3 × R$ 214,80'), findsOneWidget);
    expect(find.text(r'R$ 644,40'), findsOneWidget);

    final ordem = [
      'Total dos produtos',
      'Insumos',
      'Impostos',
      'Combustível',
      'Outros: Frete',
      'Subtotal',
      'Desconto',
      'Total geral',
    ];
    for (var i = 1; i < ordem.length; i++) {
      expect(
        topo(tester, ordem[i]),
        greaterThan(topo(tester, ordem[i - 1])),
        reason: '${ordem[i]} depois de ${ordem[i - 1]}',
      );
    }
    expect(find.text(r'R$ 3.350,80'), findsOneWidget);
    expect(find.text(r'R$ 3.730,80'), findsOneWidget);
    expect(find.text(r'− R$ 100,00'), findsOneWidget);
    expect(find.text(r'R$ 3.630,80'), findsOneWidget);
    expect(
      find.text('Prazo de entrega a combinar na aprovação.'),
      findsOneWidget,
    );
    expect(find.byType(AvisoTotalZero), findsNothing);
  });

  testWidgets('sem mostrarPecas, nenhum custo de peça ou material aparece', (
    tester,
  ) async {
    await montar(tester, PreviaOrcamento.deOrcamento(orcamentoExemploC));

    expect(find.text('PEÇAS (USO INTERNO)'), findsNothing);
    expect(find.text('1 × Tampo'), findsNothing);
    expect(find.text(r'R$ 486,00'), findsNothing);
    expect(find.textContaining('Materiais por produto'), findsNothing);
  });

  testWidgets('com mostrarPecas, mostra o detalhe interno das peças', (
    tester,
  ) async {
    await montar(
      tester,
      PreviaOrcamento.deOrcamento(orcamentoExemploC, mostrarPecas: true),
    );

    expect(find.text('PEÇAS (USO INTERNO)'), findsNWidgets(2));
    expect(find.text('1 × Tampo'), findsOneWidget);
    expect(find.text(r'R$ 486,00'), findsOneWidget);
    expect(find.text('4 × Perna'), findsOneWidget);
    expect(find.text(r'R$ 67,20'), findsOneWidget);
    expect(find.text('180 × 90 cm • 1,62 m²'), findsOneWidget);
    expect(find.text(r'R$ 553,20'), findsOneWidget);
  });

  testWidgets('exemplo B: sem adicionais nem desconto, sem validade', (
    tester,
  ) async {
    await montar(tester, PreviaOrcamento.deOrcamento(orcamentoExemploB));

    for (final rotulo in ['Insumos', 'Impostos', 'Combustível', 'Desconto']) {
      expect(find.text(rotulo), findsNothing);
    }
    expect(find.textContaining('Outros'), findsNothing);
    expect(find.textContaining('Válido até'), findsNothing);
    expect(find.text('Subtotal'), findsOneWidget);
  });

  testWidgets('total geral zero aparece destacado', (tester) async {
    final zerado = salvarExemplo(
      edicaoExemploB(
        idsPrevisiveis('z'),
      ).copyWith(desconto: Dinheiro.parse('644,40')),
      id: 'orcamento-zero',
      codigo: '091023-01',
      em: DateTime(2023, 10, 9),
    );
    await montar(tester, PreviaOrcamento.deOrcamento(zerado));

    expect(find.text(r'R$ 0,00'), findsOneWidget);
    expect(find.byType(AvisoTotalZero), findsOneWidget);
  });

  testWidgets('sessão nova: número gerado ao finalizar e validade de agora', (
    tester,
  ) async {
    final edicao = edicaoExemploC(idsPrevisiveis('e'));
    await montar(
      tester,
      PreviaOrcamento.daEdicao(
        edicao,
        resumo: orcamentoExemploC.totais,
        agora: DateTime(2026, 10, 26, 10),
      ),
    );

    expect(find.text('Número gerado ao finalizar'), findsOneWidget);
    expect(find.text('Emissão: 26/10/2026'), findsOneWidget);
    expect(find.text('Válido até 10/11/2026'), findsOneWidget);
  });

  testWidgets('edição: código com a próxima revisão (D-30)', (tester) async {
    final edicao = edicaoExemploC(idsPrevisiveis('e')).copyWith(
      orcamentoOrigemId: 'orcamento-c',
      codigo: '071023-01',
      revisao: 2,
    );
    await montar(
      tester,
      PreviaOrcamento.daEdicao(
        edicao,
        resumo: orcamentoExemploC.totais,
        agora: DateTime(2026, 10, 26, 10),
      ),
    );

    expect(find.text('Nº 071023-01 rev. 3'), findsOneWidget);
  });

  for (final modo in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('360 dp com as peças, sem transbordar (${modo.name})', (
      tester,
    ) async {
      await montar(
        tester,
        PreviaOrcamento.deOrcamento(orcamentoExemploC, mostrarPecas: true),
        themeMode: modo,
        tamanho: const Size(360, 640),
      );

      expect(tester.takeException(), isNull);
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });
  }
}
