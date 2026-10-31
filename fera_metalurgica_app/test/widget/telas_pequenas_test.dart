import 'package:fera_metalurgica_app/core/router/app_router.dart';
import 'package:fera_metalurgica_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../mocks/container_de_teste.dart';
import 'orcamentos/wizard/wizard_teste_helpers.dart';

/// Marcadores nas rotas para os orçamentos de exemplo, cujos ids são UUIDs
/// gerados ao gravar: `{C}` (A + B) e `{B}`.
const String _c = '{C}';
const String _b = '{B}';

/// Abre todas as telas com os dados de exemplo em telas pequenas e grandes,
/// nos modos claro e escuro (RNF-01), e confere as diretrizes de
/// acessibilidade do Flutter (RNF-06). Qualquer transbordamento de layout
/// falha o teste.
void main() {
  final rotas = <String>[
    AppRoutes.dashboard,
    AppRoutes.orcamentos,
    AppRoutes.agenda,
    AppRoutes.mais,
    AppRoutes.materiais,
    AppRoutes.material(),
    AppRoutes.empresa,
    AppRoutes.novoOrcamento(),
    AppRoutes.detalhesOrcamento(_c),
    AppRoutes.detalhesOrcamento(_b),
    AppRoutes.editarOrcamento(_c),
    AppRoutes.pdfOrcamento(_c),
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
    // Como `feraAppDeTeste()`, trocando os marcadores pelos ids gravados.
    final overrides = await overridesDeTeste();
    final [b, c] = await orcamentosGravados(overrides);
    appRouter.go(rota.replaceAll(_c, c.id).replaceAll(_b, b.id));
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: FeraApp(themeMode: tema),
      ),
    );
    await tester.pumpAndSettle();
  }

  // As etapas 2 a 4 do wizard não têm rota (D-11): a edição do exemplo C,
  // que já tem cliente e produtos, avança até elas pelo "Continuar".
  for (final tema in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('etapas do wizard em 360 dp, ${tema.name}', (tester) async {
      final semantics = tester.ensureSemantics();
      await abrir(
        tester,
        AppRoutes.editarOrcamento(_c),
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

    testWidgets('etapa 1 com busca e aviso em 360 dp, ${tema.name}', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await abrir(
        tester,
        AppRoutes.editarOrcamento(_c),
        tamanho: tamanhos['360 dp']!,
        tema: tema,
      );
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('cliente-documento')),
          matching: find.byType(EditableText),
        ),
        '11.222.333/0001-81',
      );
      await tester.enterText(
        find.byKey(const ValueKey('wizard-busca-cliente')),
        'Silva',
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('cliente-aviso-outro-cadastro')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      semantics.dispose();
    });
  }

  // Folhas e diálogos não têm rota: abre cada um a partir da tela dona.
  final sobreposicoes = <(String, String, List<Finder> Function())>[
    (
      'diálogo "Descartar orçamento?"',
      AppRoutes.novoOrcamento(),
      () => [find.byTooltip('Voltar')],
    ),
    (
      'diálogo "Descartar alterações?"',
      AppRoutes.editarOrcamento(_c),
      () => [find.byTooltip('Voltar')],
    ),
    (
      'diálogo "Alterar status"',
      AppRoutes.detalhesOrcamento(_c),
      () => [find.byTooltip('Mais opções'), find.text('Alterar status')],
    ),
    (
      'formulário de produto (etapa 2)',
      AppRoutes.editarOrcamento(_c),
      () => [continuar, find.text('Novo produto')],
    ),
    (
      'seletor de material (etapa 2)',
      AppRoutes.editarOrcamento(_c),
      () => [
        continuar,
        find.text('Novo produto'),
        find.byKey(const ValueKey('peca-material')),
      ],
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
