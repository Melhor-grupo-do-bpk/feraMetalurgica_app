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

import '../../mocks/mock_cronograma_repository.dart';

void main() {
  late MockCronogramaRepository repository;
  late List<Tarefa> salvas;

  setUpAll(() => registerFallbackValue(cronogramaSeed.first));

  setUp(() {
    salvas = [...cronogramaSeed];
    repository = MockCronogramaRepository();
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
  }) async {
    tester.view
      ..physicalSize = const Size(360, 3000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: AppRoutes.cronograma,
      routes: [
        GoRoute(
          path: AppRoutes.cronograma,
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
          cronogramaRepositoryProvider.overrideWithValue(repository),
          agoraProvider.overrideWithValue(DateTime(2023, 10, 9, 8)),
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

      expect(find.text('Outubro 2023'), findsOneWidget);
      expect(find.text('FILTROS DE TAREFAS'), findsOneWidget);
      expect(find.text('Hoje, 9 Out'), findsOneWidget);
      expect(find.text('Amanhã, 10 Out'), findsOneWidget);
      expect(find.text('Qua, 11 Out'), findsOneWidget);

      expect(find.text('Hoje'), findsOneWidget);
      expect(find.text('2 tarefas'), findsOneWidget);
      expect(find.text('Amanhã'), findsOneWidget);
      expect(find.text('1 tarefa'), findsOneWidget);
      expect(find.text('Revisar orçamento #00482'), findsOneWidget);
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
    expect(find.text('Revisar orçamento #00482'), findsOneWidget);
    expect(find.text('1 tarefa'), findsOneWidget);
    expect(find.text('0 tarefas'), findsOneWidget);
    expect(find.text('Nenhuma tarefa neste dia'), findsOneWidget);
    expect(pontos(), findsNothing);
  });

  testWidgets('tocar no círculo conclui a tarefa', (tester) async {
    await abrirCronograma(tester);

    await tester.tap(
      find.descendant(
        of: tarefa('tarefa-revisar-00482'),
        matching: find.byKey(const ValueKey('timeline-marcador')),
      ),
    );
    await tester.pumpAndSettle();

    final salva =
        verify(() => repository.save(captureAny())).captured.single as Tarefa;
    expect((salva.id, salva.concluida), ('tarefa-revisar-00482', true));
    final tile = tester.widget<TimelineTile>(
      find.descendant(
        of: tarefa('tarefa-revisar-00482'),
        matching: find.byType(TimelineTile),
      ),
    );
    expect(tile.concluida, isTrue);
    expect(find.text('Ver Detalhes'), findsNothing);
  });

  testWidgets('atalho de dia muda a seleção e a linha do tempo', (
    tester,
  ) async {
    await abrirCronograma(tester);

    // Num celular, o terceiro atalho começa fora da tela.
    await tester.ensureVisible(find.text('Qua, 11 Out'));
    await tester.tap(find.text('Qua, 11 Out'));
    await tester.pumpAndSettle();

    // "Qua, 11 Out" agora é o primeiro atalho e o título da seção.
    expect(find.text('Qua, 11 Out'), findsNWidgets(2));
    expect(find.text('Qui, 12 Out'), findsNWidgets(2));
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
    expect(find.text('Qua, 11 Out'), findsNWidgets(2));
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
    expect(find.text('Dom, 27 Ago'), findsNWidgets(2));
  });

  testWidgets('"Ver Detalhes" abre o orçamento', (tester) async {
    await abrirCronograma(tester);

    await tester.tap(find.text('Ver Detalhes'));
    await tester.pumpAndSettle();

    expect(find.text('detalhes 00482'), findsOneWidget);
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

    when(() => repository.getAll()).thenAnswer((_) async => cronogramaSeed);
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();

    expect(find.text('2 tarefas'), findsOneWidget);
  });

  test('montarAgenda e rótulos', () {
    final agenda = montarAgenda(
      cronogramaSeed,
      diaSelecionado: DateTime(2023, 10, 9, 15),
      tipos: TipoTarefa.values.toSet(),
    );
    expect(agenda.secoes.map((s) => s.tarefas.length), [2, 1]);
    expect(agenda.diasComPendencia, {
      DateTime(2023, 10, 9),
      DateTime(2023, 10, 10),
    });

    final hoje = DateTime(2023, 10, 9, 8);
    expect(rotuloAtalho(DateTime(2023, 10, 9), hoje), 'Hoje, 9 Out');
    expect(rotuloAtalho(DateTime(2023, 10, 10), hoje), 'Amanhã, 10 Out');
    expect(rotuloAtalho(DateTime(2023, 10, 11), hoje), 'Qua, 11 Out');
    expect(contarTarefas(0), '0 tarefas');
    expect(contarTarefas(1), '1 tarefa');
  });
}
