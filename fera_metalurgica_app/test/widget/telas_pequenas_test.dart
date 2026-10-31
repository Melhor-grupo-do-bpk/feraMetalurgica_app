import 'package:fera_metalurgica_app/core/di/banco_de_dados.dart';
import 'package:fera_metalurgica_app/core/di/relogio_provider.dart';
import 'package:fera_metalurgica_app/core/router/app_router.dart';
import 'package:fera_metalurgica_app/features/cronograma/cronograma.dart';
import 'package:fera_metalurgica_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../mocks/container_de_teste.dart';
import 'core/teste_helpers.dart';
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
    AppRoutes.material(id: 'material-granito'),
    AppRoutes.tarefa(orcamentoId: _c),
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
    Future<void> Function(ProviderContainer container)? preparar,
  }) async {
    tester.view
      ..physicalSize = tamanho
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    // Como `feraAppDeTeste()`, trocando os marcadores pelos ids gravados.
    final overrides = await overridesDeTeste();
    if (preparar != null) {
      final container = ProviderContainer(overrides: overrides);
      try {
        await preparar(container);
      } finally {
        container.dispose();
      }
    }
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

    // Os exemplos não têm tarefa atrasada: grava uma pendente de anteontem.
    testWidgets('folha "tarefas atrasadas" em 360 dp, ${tema.name}', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await abrir(
        tester,
        AppRoutes.agenda,
        tamanho: tamanhos['360 dp']!,
        tema: tema,
        preparar: _gravarAtrasada,
      );
      await tocar(tester, find.text('Ver'));

      expect(find.text('Visita atrasada'), findsWidgets);
      expect(tester.takeException(), isNull);
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
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

  // Formulários de cadastro com os erros de obrigatório à vista (HO-V2-C-01):
  // confere no fim da lista, onde fica o "Salvar", e de novo no topo.
  final formularios =
      <(String, String, String, Future<void> Function(ProviderContainer)?)>[
        (
          'formulário de material',
          AppRoutes.material(),
          'Salvar material',
          null,
        ),
        (
          'dados da empresa',
          AppRoutes.empresa,
          'Salvar dados',
          (container) => container.read(bancoDeDadosProvider).delete('empresa'),
        ),
      ];
  for (final (nome, rota, salvar, preparar) in formularios) {
    for (final tema in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('$nome com os erros em 360 dp, ${tema.name}', (tester) async {
        final semantics = tester.ensureSemantics();
        await abrir(
          tester,
          rota,
          tamanho: tamanhos['360 dp']!,
          tema: tema,
          preparar: preparar,
        );
        await tocar(tester, find.text(salvar));
        expect(find.text('Campo obrigatório'), findsWidgets);
        await conferirAcessibilidade(tester);

        await tester.drag(find.byType(Scrollable).first, const Offset(0, 5000));
        await tester.pumpAndSettle();
        expect(find.text('Campo obrigatório'), findsWidgets);
        await conferirAcessibilidade(tester);
        semantics.dispose();
      });
    }
  }

  // O aviso de atrasadas no topo da agenda (D-41), em todos os tamanhos.
  for (final MapEntry(key: nome, value: tamanho) in tamanhos.entries) {
    for (final tema in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('aviso de atrasadas na agenda em $nome, ${tema.name}', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        await abrir(
          tester,
          AppRoutes.agenda,
          tamanho: tamanho,
          tema: tema,
          preparar: _gravarAtrasada,
        );

        expect(find.byKey(const ValueKey('aviso-atrasadas')), findsOneWidget);
        await conferirAcessibilidade(tester);
        semantics.dispose();
      });
    }
  }

  // Folhas e diálogos não têm rota: abre cada um a partir da tela dona.
  final sobreposicoes = <(String, String, List<Finder> Function())>[
    (
      'diálogo "Inativar material?"',
      AppRoutes.materiais,
      () => [
        find.byTooltip('Ações do material MDF 15 mm'),
        find.text('Inativar'),
      ],
    ),
    (
      'diálogo "A unidade não pode mudar" (material em uso)',
      AppRoutes.material(id: 'material-granito'),
      () => [find.text('m³')],
    ),
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
      'diálogo "Excluir o orçamento?"',
      AppRoutes.detalhesOrcamento(_c),
      () => [find.byTooltip('Mais opções'), find.text('Excluir')],
    ),
    (
      'diálogo "Voltar para criado?"',
      AppRoutes.detalhesOrcamento(_c),
      () => [
        find.byTooltip('Mais opções'),
        find.text('Marcar como enviado'),
        find.byTooltip('Mais opções'),
        find.text('Voltar para criado'),
      ],
    ),
    (
      'diálogo "Excluir tarefa?"',
      AppRoutes.tarefa(id: 'tarefa-producao-00124'),
      () => [find.text('Excluir tarefa')],
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

/// Grava uma tarefa pendente de anteontem: os exemplos não têm atrasadas.
Future<void> _gravarAtrasada(ProviderContainer container) async {
  final agora = container.read(agoraProvider);
  await container
      .read(tarefaRepositoryProvider)
      .save(
        Tarefa(
          id: 'tarefa-atrasada',
          titulo: 'Visita atrasada',
          data: agora.subtract(const Duration(days: 2)),
          tipo: TipoTarefa.visita,
        ),
      );
}
