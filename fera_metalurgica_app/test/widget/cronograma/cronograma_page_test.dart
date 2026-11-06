import 'package:fera_metalurgica_app/core/di/relogio_provider.dart';
import 'package:fera_metalurgica_app/core/router/app_routes.dart';
import 'package:fera_metalurgica_app/core/theme/app_theme.dart';
import 'package:fera_metalurgica_app/core/widgets/timeline_tile.dart';
import 'package:fera_metalurgica_app/features/cronograma/cronograma.dart';
import 'package:fera_metalurgica_app/features/cronograma/presentation/cronograma/agenda_filtro.dart';
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
    // A revisão vinculada ao exemplo C.
    salvas = [
      tarefasExemplo.first.copyWith(orcamentoId: 'orcamento-c'),
      ...tarefasExemplo.skip(1),
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

  /// Abre o cronograma com "agora" fixo em 09/10/2023 08:00 (dia do Figma).
  /// O formulário e os detalhes viram textos com o parâmetro recebido, para
  /// conferir a navegação sem abrir as telas reais.
  Future<void> abrirCronograma(
    WidgetTester tester, {
    ThemeMode themeMode = ThemeMode.light,
    DateTime? agora,
  }) async {
    tester.view
      ..physicalSize = const Size(360, 3000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: AppRoutes.agenda,
      routes: [
        GoRoute(
          path: AppRoutes.agenda,
          builder: (_, _) => const CronogramaPage(),
          routes: [
            GoRoute(
              path: 'tarefa',
              builder: (_, state) =>
                  Text('tarefa ${state.uri.queryParameters['id']}'),
            ),
          ],
        ),
        GoRoute(
          path: '${AppRoutes.orcamentos}/:id',
          builder: (_, state) => Text('detalhes ${state.pathParameters['id']}'),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tarefaRepositoryProvider.overrideWithValue(repository),
          agoraProvider.overrideWithValue(agora ?? DateTime(2023, 10, 9, 8)),
        ],
        // Sem o retry automático do Riverpod, para o erro aparecer na hora.
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

  Finder tarefa(String id) => find.byKey(ValueKey('tarefa-$id'));

  Finder pontos() => find.byKey(const ValueKey('calendario-ponto'));

  for (final modo in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('mostra hoje e amanhã com o seed (${modo.name})', (
      tester,
    ) async {
      await abrirCronograma(tester, themeMode: modo);

      // Raiz da aba "Agenda" (D-31): título, sem voltar.
      expect(find.text('Agenda'), findsOneWidget);
      expect(find.byTooltip('Voltar'), findsNothing);
      expect(find.text('Outubro 2023'), findsOneWidget);
      expect(find.text('FILTROS DE TAREFAS'), findsOneWidget);
      expect(find.text('Hoje'), findsOneWidget);
      expect(find.text('2 tarefas'), findsOneWidget);
      expect(find.text('Amanhã'), findsOneWidget);
      expect(find.text('1 tarefa'), findsOneWidget);
      expect(find.text('Revisar orçamento'), findsOneWidget);
      expect(find.text('Manutenção preventiva Torno CNC'), findsOneWidget);
      expect(find.text('Iniciar produção do pedido #00124'), findsOneWidget);
      expect(find.text('09:00'), findsOneWidget);
      expect(find.text('Ver Detalhes'), findsOneWidget);

      // Ponto só no dia 10: o 9 também tem pendência, mas está selecionado.
      expect(pontos(), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('calendario-dia-10/10/2023')),
          matching: pontos(),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('desmarcar Produção esconde as tarefas de produção', (
    tester,
  ) async {
    await abrirCronograma(tester);

    await tester.tap(find.widgetWithText(CheckboxListTile, 'Produção'));
    await tester.pumpAndSettle();

    expect(find.text('Manutenção preventiva Torno CNC'), findsNothing);
    expect(find.text('Iniciar produção do pedido #00124'), findsNothing);
    expect(find.text('Revisar orçamento'), findsOneWidget);
    expect(find.text('1 tarefa'), findsOneWidget);
    expect(find.text('0 tarefas'), findsOneWidget);
    expect(find.text('Nenhuma tarefa neste dia'), findsOneWidget);
    expect(pontos(), findsNothing);
  });

  testWidgets('tocar no círculo conclui a tarefa', (tester) async {
    await abrirCronograma(tester);

    await tester.tap(
      find.descendant(
        of: tarefa('tarefa-revisar-orcamento'),
        matching: find.byKey(const ValueKey('timeline-marcador')),
      ),
    );
    await tester.pumpAndSettle();

    final salva =
        verify(() => repository.save(captureAny())).captured.single as Tarefa;
    expect((salva.id, salva.concluida), ('tarefa-revisar-orcamento', true));
    final tile = tester.widget<TimelineTile>(
      find.descendant(
        of: tarefa('tarefa-revisar-orcamento'),
        matching: find.byType(TimelineTile),
      ),
    );
    expect(tile.concluida, isTrue);
    expect(find.text('Ver Detalhes'), findsNothing);
  });

  testWidgets('escolher um dia sem tarefas muda a linha do tempo', (
    tester,
  ) async {
    await abrirCronograma(tester);

    await tester.tap(find.byKey(const ValueKey('calendario-dia-11/10/2023')));
    await tester.pumpAndSettle();

    expect(find.text('Qua, 11 Out'), findsOneWidget);
    expect(find.text('Qui, 12 Out'), findsOneWidget);
    expect(find.text('Hoje'), findsNothing);
    expect(find.text('0 tarefas'), findsNWidgets(2));
    // Fora da seleção, o dia 9 volta a mostrar o ponto.
    expect(pontos(), findsNWidgets(2));
  });

  testWidgets('tocar num dia do calendário seleciona o dia', (tester) async {
    await abrirCronograma(tester);

    await tester.tap(find.byKey(const ValueKey('calendario-dia-10/10/2023')));
    await tester.pumpAndSettle();

    expect(find.text('Amanhã'), findsOneWidget);
    expect(find.text('Qua, 11 Out'), findsOneWidget);
    expect(find.text('Iniciar produção do pedido #00124'), findsOneWidget);
  });

  testWidgets('‹ › trocam o mês sem mudar a seleção', (tester) async {
    await abrirCronograma(tester);

    await tester.tap(find.byTooltip('Próximo mês'));
    await tester.pumpAndSettle();
    expect(find.text('Novembro 2023'), findsOneWidget);
    expect(find.text('Hoje'), findsOneWidget);

    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byTooltip('Mês anterior'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Setembro 2023'), findsOneWidget);

    // Selecionar um dia de outro mês leva o calendário para o mês dele.
    await tester.tap(find.byKey(const ValueKey('calendario-dia-27/08/2023')));
    await tester.pumpAndSettle();
    expect(find.text('Agosto 2023'), findsOneWidget);
    expect(find.text('Dom, 27 Ago'), findsOneWidget);
  });

  testWidgets('"Ver Detalhes" abre o orçamento', (tester) async {
    await abrirCronograma(tester);

    await tester.tap(find.text('Ver Detalhes'));
    await tester.pumpAndSettle();

    expect(find.text('detalhes orcamento-c'), findsOneWidget);
  });

  testWidgets('"+" abre uma tarefa nova', (tester) async {
    await abrirCronograma(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('tarefa null'), findsOneWidget);
  });

  testWidgets('tocar e segurar abre a edição da tarefa', (tester) async {
    await abrirCronograma(tester);

    await tester.longPress(find.text('Iniciar produção do pedido #00124'));
    await tester.pumpAndSettle();

    expect(find.text('tarefa tarefa-producao-00124'), findsOneWidget);
  });

  testWidgets('erro ao carregar mostra "Tentar novamente"', (tester) async {
    when(() => repository.getAll()).thenThrow(Exception('falhou'));
    await abrirCronograma(tester);

    expect(find.text('Não foi possível carregar as tarefas.'), findsOneWidget);

    when(() => repository.getAll()).thenAnswer((_) async => tarefasExemplo);
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();

    expect(find.text('2 tarefas'), findsOneWidget);
  });

  testWidgets('"Todas" mostra as tarefas de todos os dias', (tester) async {
    salvas = [
      ...salvas,
      Tarefa(
        id: 'tarefa-distante',
        titulo: 'Entrega distante',
        data: DateTime(2023, 12, 20, 10),
        tipo: TipoTarefa.visita,
      ),
    ];
    await abrirCronograma(tester);
    expect(find.text('Entrega distante'), findsNothing);

    await tester.tap(find.text('Todas'));
    await tester.pumpAndSettle();
    expect(find.text('Entrega distante'), findsOneWidget);

    // Escolher um dia no calendário volta à visão por dia.
    await tester.tap(find.text('15'));
    await tester.pumpAndSettle();
    expect(find.text('Entrega distante'), findsNothing);
  });

  testWidgets('"Todas" sem tarefas avisa que não há nada agendado', (
    tester,
  ) async {
    salvas = [];
    await abrirCronograma(tester);

    await tester.tap(find.text('Todas'));
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma tarefa agendada.'), findsOneWidget);
  });

  test('montarAgenda com todas agrupa por dia, em ordem', () {
    final agenda = montarAgenda(
      [
        ...tarefasExemplo,
        Tarefa(
          id: 'antiga',
          titulo: 'Antiga',
          data: DateTime(2023, 1, 2, 9),
          tipo: TipoTarefa.visita,
          concluida: true,
        ),
      ],
      diaSelecionado: DateTime(2023, 10, 9),
      tipos: TipoTarefa.values.toSet(),
      todas: true,
    );

    expect(agenda.secoes.map((s) => s.dia), [
      DateTime(2023, 1, 2),
      DateTime(2023, 10, 9),
      DateTime(2023, 10, 10),
    ]);
    expect(agenda.secoes.map((s) => s.tarefas.length), [1, 2, 1]);
  });

  test('montarAgenda e rótulos', () {
    final agenda = montarAgenda(
      tarefasExemplo,
      diaSelecionado: DateTime(2023, 10, 9, 15),
      tipos: TipoTarefa.values.toSet(),
    );
    expect(agenda.secoes.map((s) => s.tarefas.length), [2, 1]);
    expect(agenda.diasComPendencia, {
      DateTime(2023, 10, 9),
      DateTime(2023, 10, 10),
    });

    expect(contarTarefas(0), '0 tarefas');
    expect(contarTarefas(1), '1 tarefa');
  });

  group('tarefas atrasadas', () {
    Finder aviso() => find.byKey(const ValueKey('aviso-atrasadas'));

    // Uma visita pendente de sábado (7) e uma concluída de sexta (6).
    setUp(() {
      salvas = [
        Tarefa(
          id: 'visita-sabado',
          titulo: 'Visita na obra',
          data: DateTime(2023, 10, 7, 16),
          tipo: TipoTarefa.visita,
        ),
        Tarefa(
          id: 'medicao-sexta',
          titulo: 'Medição do vão',
          data: DateTime(2023, 10, 6, 10),
          tipo: TipoTarefa.visita,
          concluida: true,
        ),
        ...salvas,
      ];
    });

    for (final modo in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('aviso com a contagem no topo (${modo.name})', (
        tester,
      ) async {
        await abrirCronograma(tester, themeMode: modo);

        expect(aviso(), findsOneWidget);
        expect(find.text('1 tarefa atrasada'), findsOneWidget);
        expect(
          tester.getTopLeft(aviso()).dy,
          lessThan(tester.getTopLeft(find.text('Outubro 2023')).dy),
        );
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('a contagem usa o agoraProvider', (tester) async {
      // Em 11/10, a revisão (9) e a produção (10), pendentes, também
      // atrasaram; a hora já passada de hoje não conta.
      await abrirCronograma(tester, agora: DateTime(2023, 10, 11, 23));

      expect(find.text('3 tarefas atrasadas'), findsOneWidget);
    });

    testWidgets('sem atrasadas, sem aviso', (tester) async {
      salvas = [...tarefasExemplo];
      await abrirCronograma(tester, agora: DateTime(2023, 10, 9, 23, 59));

      expect(aviso(), findsNothing);
    });

    testWidgets('o aviso conta todas, apesar dos filtros', (tester) async {
      await abrirCronograma(tester);

      await tester.tap(find.widgetWithText(CheckboxListTile, 'Visitas'));
      await tester.pumpAndSettle();

      expect(find.text('1 tarefa atrasada'), findsOneWidget);
    });

    for (final modo in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('"Ver" lista e leva ao dia da tarefa (${modo.name})', (
        tester,
      ) async {
        await abrirCronograma(tester, themeMode: modo);

        await tester.tap(find.text('Ver'));
        await tester.pumpAndSettle();
        final folha = find.byType(BottomSheet);
        expect(
          find.descendant(of: folha, matching: find.text('Visita na obra')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: folha, matching: find.text('Medição do vão')),
          findsNothing,
        );
        expect(find.text('07/10/2023 • 16:00'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.byKey(const ValueKey('atrasada-visita-sabado')));
        await tester.pumpAndSettle();

        expect(folha, findsNothing);
        expect(find.text('Sáb, 7 Out'), findsWidgets);
        expect(tarefa('visita-sabado'), findsOneWidget);
      });
    }

    // O aviso e a folha não aparecem no `telas_pequenas_test` (os exemplos
    // não têm atrasadas): as diretrizes de acessibilidade ficam aqui.
    for (final modo in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('aviso e folha: contraste e áreas de toque (${modo.name})', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        await abrirCronograma(tester, themeMode: modo);
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

        await tester.tap(find.text('Ver'));
        await tester.pumpAndSettle();
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        semantics.dispose();
      });
    }

    testWidgets('destaca a tarefa atrasada no dia dela', (tester) async {
      await abrirCronograma(tester);
      await tester.tap(find.byKey(const ValueKey('calendario-dia-07/10/2023')));
      await tester.pumpAndSettle();

      final atrasada = tester.widget<TimelineTile>(
        find.descendant(
          of: tarefa('visita-sabado'),
          matching: find.byType(TimelineTile),
        ),
      );
      final contexto = tester.element(tarefa('visita-sabado'));
      expect(atrasada.corDestaque, Theme.of(contexto).colorScheme.error);
      expect(
        find.descendant(
          of: tarefa('visita-sabado'),
          matching: find.text('ATRASADA'),
        ),
        findsOneWidget,
      );
      // Quinta e sexta: a concluída de sexta não é atrasada.
      await tester.tap(find.byKey(const ValueKey('calendario-dia-05/10/2023')));
      await tester.pumpAndSettle();
      expect(find.text('ATRASADA'), findsNothing);
    });
  });
}
