import 'dart:async';

import 'package:fera_metalurgica_app/core/di/relogio_provider.dart';
import 'package:fera_metalurgica_app/core/domain/dinheiro.dart';
import 'package:fera_metalurgica_app/core/router/app_routes.dart';
import 'package:fera_metalurgica_app/core/theme/app_theme.dart';
import 'package:fera_metalurgica_app/core/widgets/stat_card.dart';
import 'package:fera_metalurgica_app/core/widgets/status_chip.dart';
import 'package:fera_metalurgica_app/features/cronograma/cronograma.dart';
import 'package:fera_metalurgica_app/features/dashboard/dashboard.dart';
import 'package:fera_metalurgica_app/features/dashboard/presentation/orcamento_recente_card.dart';
import 'package:fera_metalurgica_app/features/orcamentos/orcamentos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../mocks/dados_exemplo.dart';
import '../mocks/mock_orcamento_repository.dart';
import '../mocks/mock_tarefa_repository.dart';

/// O exemplo B (R$ 644,40) com [id], [status] e salvo em [dia] de
/// outubro de 2023; enviado, com o `enviadoEm` em [enviadoEm].
Orcamento _orcamento(
  String id,
  StatusOrcamento status,
  int dia, {
  DateTime? enviadoEm,
}) => orcamentoExemploB.copyWith(
  id: id,
  codigo: '${dia.toString().padLeft(2, '0')}1023-01',
  status: status,
  enviadoEm: enviadoEm,
  criadoEm: DateTime(2023, 10, dia),
  atualizadoEm: DateTime(2023, 10, dia),
);

/// Contagens diferentes em cada card (D-32), no mês de [agoraDosExemplos]
/// (outubro de 2023): 3 criados e 2 enviados em outubro; o enviado em
/// setembro não conta. Do `atualizadoEm` mais recente ao mais antigo.
final List<Orcamento> _orcamentos = [
  _orcamento('o8', StatusOrcamento.criado, 8),
  _orcamento(
    'o7',
    StatusOrcamento.enviado,
    7,
    enviadoEm: DateTime(2023, 10, 7),
  ),
  _orcamento('o6', StatusOrcamento.criado, 6),
  _orcamento(
    'o5',
    StatusOrcamento.enviado,
    5,
    enviadoEm: DateTime(2023, 10, 5),
  ),
  _orcamento('o4', StatusOrcamento.criado, 4),
  _orcamento(
    'o3',
    StatusOrcamento.enviado,
    3,
    enviadoEm: DateTime(2023, 9, 30),
  ),
];

/// 4 tarefas de produção pendentes, mais uma concluída e uma de outro
/// tipo, que não contam.
final List<Tarefa> _tarefas = [
  for (var i = 0; i < 4; i++) tarefasExemplo.last.copyWith(id: 'producao-$i'),
  tarefasExemplo.last.copyWith(id: 'concluida', concluida: true),
  tarefasExemplo.first,
];

void main() {
  late MockOrcamentoRepository orcamentos;
  late MockTarefaRepository tarefas;

  setUp(() {
    orcamentos = MockOrcamentoRepository();
    tarefas = MockTarefaRepository();
    when(orcamentos.listarResumos).thenAnswer((_) async => _orcamentos);
    when(() => tarefas.getAll()).thenAnswer((_) async => _tarefas);
  });

  /// Monta o dashboard num router mínimo: wizard, lista e detalhes viram
  /// textos, para conferir a navegação sem abrir as telas de outras
  /// trilhas.
  Future<void> abrirDashboard(
    WidgetTester tester, {
    ThemeMode themeMode = ThemeMode.light,
    bool aguardar = true,
    Size tamanho = const Size(800, 2400),
  }) async {
    tester.view
      ..physicalSize = tamanho
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: AppRoutes.dashboard,
      routes: [
        GoRoute(
          path: AppRoutes.dashboard,
          builder: (_, _) => const DashboardPage(),
        ),
        GoRoute(
          path: AppRoutes.orcamentos,
          builder: (_, _) => const Text('lista'),
          routes: [
            GoRoute(path: 'novo', builder: (_, _) => const Text('wizard')),
            GoRoute(
              path: ':id',
              builder: (_, state) =>
                  Text('detalhes ${state.pathParameters['id']}'),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        // Sem o retry automático do Riverpod, para o erro aparecer na hora.
        retry: (_, _) => null,
        overrides: [
          orcamentoRepositoryProvider.overrideWithValue(orcamentos),
          tarefaRepositoryProvider.overrideWithValue(tarefas),
          agoraProvider.overrideWithValue(agoraDosExemplos),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          routerConfig: router,
        ),
      ),
    );
    if (aguardar) await tester.pumpAndSettle();
  }

  /// Valor exibido no [StatCard] de rótulo [label].
  String valorDoCard(WidgetTester tester, String label) => tester
      .widget<StatCard>(
        find.byWidgetPredicate((w) => w is StatCard && w.label == label),
      )
      .valor;

  testWidgets('mostra o CTA, os 4 indicadores e os valores (D-32)', (
    tester,
  ) async {
    await abrirDashboard(tester);

    expect(find.text('Criar orçamento'), findsOneWidget);
    expect(valorDoCard(tester, 'Criados'), '03');
    expect(valorDoCard(tester, 'Enviados no mês'), '02');
    expect(valorDoCard(tester, 'Valor enviado no mês'), r'R$ 1.288,80');
    expect(valorDoCard(tester, 'Pedidos em produção'), '04');
  });

  testWidgets('mostra só os 2 mais recentes, de qualquer status', (
    tester,
  ) async {
    await abrirDashboard(tester);

    expect(find.text('Orçamentos Recentes'), findsOneWidget);
    expect(find.byType(OrcamentoRecenteCard), findsNWidgets(2));
    expect(find.textContaining('081023-01'), findsOneWidget);
    expect(find.textContaining('071023-01'), findsOneWidget);
    expect(find.textContaining('061023-01'), findsNothing);
    expect(find.textContaining('08/10/2023'), findsOneWidget);
    expect(find.text('Criado'), findsOneWidget);
    expect(find.text('Enviado'), findsOneWidget);
    expect(find.text('Valor Total'), findsNWidgets(2));
    expect(
      tester
          .widgetList<StatusChip>(find.byType(StatusChip))
          .map((c) => c.showDot),
      everyElement(isTrue),
    );
  });

  testWidgets('"Criar orçamento" abre o wizard', (tester) async {
    await abrirDashboard(tester);

    await tester.tap(find.text('Criar orçamento'));
    await tester.pumpAndSettle();

    expect(find.text('wizard'), findsOneWidget);
  });

  testWidgets('"Ver todos" leva à lista de orçamentos', (tester) async {
    await abrirDashboard(tester);

    await tester.tap(find.text('Ver todos'));
    await tester.pumpAndSettle();

    expect(find.text('lista'), findsOneWidget);
  });

  testWidgets('tocar num recente abre os detalhes', (tester) async {
    await abrirDashboard(tester);

    await tester.tap(find.byType(OrcamentoRecenteCard).first);
    await tester.pumpAndSettle();

    expect(find.text('detalhes o8'), findsOneWidget);
  });

  testWidgets('mostra o carregamento enquanto os dados não chegam', (
    tester,
  ) async {
    final pendente = Completer<List<Orcamento>>();
    when(orcamentos.listarResumos).thenAnswer((_) => pendente.future);

    await abrirDashboard(tester, aguardar: false);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Criar orçamento'), findsOneWidget);
    expect(find.byType(StatCard), findsNothing);

    pendente.complete(_orcamentos);
    await tester.pumpAndSettle();
    expect(find.byType(StatCard), findsNWidgets(4));
  });

  testWidgets('sem dados: cards zerados, aviso nos recentes e CTA visível', (
    tester,
  ) async {
    when(orcamentos.listarResumos).thenAnswer((_) async => []);
    when(() => tarefas.getAll()).thenAnswer((_) async => []);

    await abrirDashboard(tester);

    expect(find.text('00'), findsNWidgets(3));
    expect(valorDoCard(tester, 'Valor enviado no mês'), r'R$ 0,00');
    expect(find.text('Nenhum orçamento ainda.'), findsOneWidget);
    expect(find.byType(OrcamentoRecenteCard), findsNothing);
    expect(find.text('Criar orçamento'), findsOneWidget);
  });

  testWidgets('erro mostra "Tentar novamente", que recarrega', (tester) async {
    when(() => tarefas.getAll()).thenThrow(Exception('falhou'));

    await abrirDashboard(tester);

    expect(find.text('Não foi possível carregar o painel.'), findsOneWidget);
    expect(find.byType(StatCard), findsNothing);

    when(() => tarefas.getAll()).thenAnswer((_) async => _tarefas);
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();

    expect(find.byType(StatCard), findsNWidgets(4));
    expect(valorDoCard(tester, 'Pedidos em produção'), '04');
  });

  testWidgets('renderiza no modo escuro', (tester) async {
    await abrirDashboard(tester, themeMode: ThemeMode.dark);

    expect(tester.takeException(), isNull);
    expect(find.byType(StatCard), findsNWidgets(4));
    expect(find.byType(OrcamentoRecenteCard), findsNWidgets(2));
  });

  testWidgets('cabe numa tela estreita sem overflow', (tester) async {
    await abrirDashboard(tester);
    tester.view.physicalSize = const Size(320, 1600);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('cabe em 360 dp no modo escuro', (tester) async {
    await abrirDashboard(tester, themeMode: ThemeMode.dark);
    tester.view.physicalSize = const Size(360, 800);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('o recente mostra a data da revisão atual (HO-V2-F2-04)', (
    tester,
  ) async {
    // Criado em 05/10 (o código), revisado e enviado em 09/10.
    when(
      orcamentos.listarResumos,
    ).thenAnswer((_) async => [orcamentoExemploEnviado, orcamentoExemploB]);
    await abrirDashboard(tester);

    expect(find.textContaining('051023-02 rev. 2'), findsOneWidget);
    expect(find.textContaining('09/10/2023'), findsOneWidget);
    expect(find.textContaining('05/10/2023'), findsNothing);
  });

  testWidgets('valor alto cabe numa linha, com os 4 cards no mesmo tamanho', (
    tester,
  ) async {
    final enviado = _orcamentos[1];
    when(orcamentos.listarResumos).thenAnswer(
      (_) async => [
        enviado.copyWith(
          totais: enviado.totais.copyWith(
            totalGeral: const Dinheiro(123456789),
          ),
        ),
      ],
    );
    await abrirDashboard(tester, tamanho: const Size(360, 800));

    expect(tester.takeException(), isNull);
    expect(
      find.descendant(
        of: find.byType(StatCard),
        matching: find.text(r'R$ 1.234.567,89'),
      ),
      findsOneWidget,
    );
    final cards = tester.widgetList<StatCard>(find.byType(StatCard));
    expect(cards.map((c) => c.tamanhoValor).toSet(), hasLength(1));
    expect(cards.first.tamanhoValor, lessThan(32));
  });

  testWidgets('gráfico mostra o mês atual e troca ao tocar na barra (D-45)', (
    tester,
  ) async {
    await abrirDashboard(tester);

    expect(find.text('ENVIADOS POR MÊS'), findsOneWidget);
    // Outubro: os 2 enviados no mês; setembro: 1.
    expect(find.text('Outubro 2023'), findsOneWidget);
    expect(find.text('2 orçamentos'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const ValueKey('grafico-mes-2023-9')),
    );
    await tester.tap(find.byKey(const ValueKey('grafico-mes-2023-9')));
    await tester.pump();

    expect(find.text('Setembro 2023'), findsOneWidget);
    expect(find.text('1 orçamento'), findsOneWidget);
  });
}
