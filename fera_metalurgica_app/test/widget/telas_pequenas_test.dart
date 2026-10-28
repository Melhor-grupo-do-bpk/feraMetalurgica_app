import 'package:fera_metalurgica_app/core/router/app_router.dart';
import 'package:fera_metalurgica_app/features/catalogo/presentation/produto_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fera_app_de_teste.dart';
import 'orcamentos/wizard/wizard_teste_helpers.dart';

/// Abre todas as telas com os dados de exemplo em telas pequenas e grandes,
/// nos modos claro e escuro (RNF-01), e confere as diretrizes de
/// acessibilidade do Flutter (RNF-06). Qualquer transbordamento de layout
/// falha o teste.
void main() {
  final rotas = <String>[
    AppRoutes.dashboard,
    AppRoutes.orcamentos,
    AppRoutes.catalogo,
    AppRoutes.mais,
    AppRoutes.cronograma,
    AppRoutes.novoOrcamento(),
    AppRoutes.detalhesOrcamento('00482'),
    AppRoutes.detalhesOrcamento('00481'),
    AppRoutes.editarOrcamento('00478'),
    AppRoutes.pdfOrcamento('00482'),
    AppRoutes.tarefa(),
    AppRoutes.tarefa(id: 'tarefa-producao-00124'),
  ];

  const tamanhos = <String, Size>{
    '360 dp': Size(360, 640),
    '412 dp': Size(412, 915),
    'tablet': Size(800, 1280),
  };

  Future<void> abrir(
    WidgetTester tester,
    String rota, {
    required Size tamanho,
    required ThemeMode tema,
  }) async {
    tester.view
      ..physicalSize = tamanho
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    appRouter.go(rota);
    await tester.pumpWidget(await feraAppDeTeste(themeMode: tema));
    await tester.pumpAndSettle();
  }

  // As etapas 2 a 4 do wizard não têm rota (D-11): a edição do #00478, que
  // já tem itens e custos, avança até elas pelo "Continuar".
  for (final tema in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('etapas do wizard em 360 dp, ${tema.name}', (tester) async {
      final semantics = tester.ensureSemantics();
      await abrir(
        tester,
        AppRoutes.editarOrcamento('00478'),
        tamanho: tamanhos['360 dp']!,
        tema: tema,
      );

      for (var etapa = 2; etapa <= 4; etapa++) {
        await tocar(tester, continuar);
        expect(find.textContaining('Etapa $etapa de 4'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      }
      semantics.dispose();
    });
  }

  // Folhas e diálogos não têm rota: abre cada um a partir da tela dona.
  final sobreposicoes = <(String, String, List<Finder> Function())>[
    (
      'folha do produto',
      AppRoutes.catalogo,
      () => [find.byType(ProdutoCard).first],
    ),
    (
      'diálogo "Alterar status"',
      AppRoutes.detalhesOrcamento('00482'),
      () => [find.byTooltip('Mais opções'), find.text('Alterar status')],
    ),
  ];
  for (final (nome, rota, toques) in sobreposicoes) {
    for (final tema in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('$nome em 360 dp, ${tema.name}', (tester) async {
        final semantics = tester.ensureSemantics();
        await abrir(tester, rota, tamanho: tamanhos['360 dp']!, tema: tema);
        for (final toque in toques()) {
          await tocar(tester, toque);
        }

        expect(tester.takeException(), isNull);
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        semantics.dispose();
      });
    }
  }

  for (final rota in rotas) {
    group(rota, () {
      for (final MapEntry(key: nome, value: tamanho) in tamanhos.entries) {
        for (final tema in [ThemeMode.light, ThemeMode.dark]) {
          testWidgets('sem transbordar em $nome, ${tema.name}', (tester) async {
            await abrir(tester, rota, tamanho: tamanho, tema: tema);

            expect(tester.takeException(), isNull);
          });
        }
      }

      for (final tema in [ThemeMode.light, ThemeMode.dark]) {
        testWidgets('contraste do texto em ${tema.name}', (tester) async {
          await abrir(tester, rota, tamanho: tamanhos['360 dp']!, tema: tema);

          await expectLater(tester, meetsGuideline(textContrastGuideline));
        });
      }

      testWidgets('áreas de toque de 48 dp e com rótulo', (tester) async {
        final semantics = tester.ensureSemantics();
        await abrir(
          tester,
          rota,
          tamanho: tamanhos['360 dp']!,
          tema: ThemeMode.light,
        );

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        semantics.dispose();
      });
    });
  }
}
