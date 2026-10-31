import 'package:fera_metalurgica_app/core/di/relogio_provider.dart';
import 'package:fera_metalurgica_app/core/router/app_routes.dart';
import 'package:fera_metalurgica_app/core/theme/app_theme.dart';
import 'package:fera_metalurgica_app/features/cronograma/cronograma.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks/dados_exemplo.dart';
import '../../mocks/mock_tarefa_repository.dart';

void main() {
  late MockTarefaRepository repository;
  late List<Tarefa> salvas;

  setUpAll(() => registerFallbackValue(tarefasExemplo.first));

  setUp(() {
    // Do orçamento C: a revisão (hoje, 09:00, pendente), a manutenção
    // (hoje, 11:30, concluída) e uma visita de ontem, pendente. A produção
    // de amanhã é do orçamento B.
    final [revisar, manutencao, producao] = tarefasExemplo;
    salvas = [
      Tarefa(
        id: 'visita-ontem',
        titulo: 'Visita na obra',
        data: DateTime(2023, 10, 8, 16),
        tipo: TipoTarefa.visita,
        orcamentoId: 'orcamento-c',
      ),
      revisar.copyWith(orcamentoId: 'orcamento-c'),
      manutencao.copyWith(orcamentoId: 'orcamento-c'),
      producao.copyWith(orcamentoId: 'orcamento-b'),
    ];
    repository = MockTarefaRepository();
    when(() => repository.getAll()).thenAnswer((_) async => [...salvas]);
    when(() => repository.save(any())).thenAnswer((invocation) async {
      final tarefa = invocation.positionalArguments.first as Tarefa;
      salvas = [
        for (final t in salvas)
          if (t.id == tarefa.id) tarefa else t,
      ];
    });
  });

  /// Monta o widget como a V2-D o usa: dentro da rolagem de uma página, a
  /// 360 dp. O formulário de tarefa vira um texto com o id recebido.
  Future<void> abrir(
    WidgetTester tester, {
    String orcamentoId = 'orcamento-c',
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    tester.view
      ..physicalSize = const Size(360, 640)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: '/detalhes',
      routes: [
        GoRoute(
          path: '/detalhes',
          builder: (_, _) => Scaffold(
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Agenda'),
                TarefasDoOrcamento(orcamentoId: orcamentoId),
                AgendarTarefaButton(orcamentoId: orcamentoId),
              ],
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.agenda,
          builder: (_, _) => const Text('agenda'),
          routes: [
            GoRoute(
              path: 'tarefa',
              builder: (_, state) => Text(
                'tarefa ${state.uri.queryParameters['id']} '
                '${state.uri.queryParameters['orcamentoId']}',
              ),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tarefaRepositoryProvider.overrideWithValue(repository),
          agoraProvider.overrideWithValue(agoraDosExemplos),
        ],
        retry: (_, _) => null,
        child: MaterialApp.router(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder linha(String id) => find.byKey(ValueKey('tarefa-orcamento-$id'));

  for (final modo in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('mostra só as tarefas do orçamento (${modo.name})', (
      tester,
    ) async {
      await abrir(tester, themeMode: modo);

      expect(linha('visita-ontem'), findsOneWidget);
      expect(linha('tarefa-revisar-orcamento'), findsOneWidget);
      expect(linha('tarefa-manutencao-torno'), findsOneWidget);
      expect(linha('tarefa-producao-00124'), findsNothing);
      expect(find.text('09/10/2023 • 09:00'), findsOneWidget);
      expect(find.text('Agendar'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('pendentes primeiro, em ordem cronológica', (tester) async {
    await abrir(tester);

    double topo(String id) => tester.getTopLeft(linha(id)).dy;
    expect(topo('visita-ontem'), lessThan(topo('tarefa-revisar-orcamento')));
    expect(
      topo('tarefa-revisar-orcamento'),
      lessThan(topo('tarefa-manutencao-torno')),
    );
  });

  testWidgets('sem tarefas mostra "Nenhuma tarefa agendada."', (tester) async {
    await abrir(tester, orcamentoId: 'orcamento-e');

    expect(find.text('Nenhuma tarefa agendada.'), findsOneWidget);
  });

  testWidgets('tocar na tarefa abre a edição', (tester) async {
    await abrir(tester);

    await tester.tap(find.text('Revisar orçamento'));
    await tester.pumpAndSettle();

    expect(find.text('tarefa tarefa-revisar-orcamento null'), findsOneWidget);
  });

  testWidgets('o marcador conclui a tarefa, que vai para o fim', (
    tester,
  ) async {
    await abrir(tester);

    await tester.tap(
      find.descendant(
        of: linha('visita-ontem'),
        matching: find.byTooltip('Marcar como concluída'),
      ),
    );
    await tester.pumpAndSettle();

    final salva =
        verify(() => repository.save(captureAny())).captured.single as Tarefa;
    expect((salva.id, salva.concluida), ('visita-ontem', true));
    expect(
      tester.getTopLeft(linha('visita-ontem')).dy,
      greaterThan(tester.getTopLeft(linha('tarefa-revisar-orcamento')).dy),
    );
  });

  testWidgets('"Agendar" abre a tarefa nova vinculada', (tester) async {
    await abrir(tester);

    await tester.tap(find.text('Agendar'));
    await tester.pumpAndSettle();

    expect(find.text('tarefa null orcamento-c'), findsOneWidget);
  });

  testWidgets('áreas de toque de 48 dp e com rótulo', (tester) async {
    final semantics = tester.ensureSemantics();
    await abrir(tester);

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    semantics.dispose();
  });

  for (final modo in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('contraste do texto (${modo.name})', (tester) async {
      await abrir(tester, themeMode: modo);

      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });
  }
}
