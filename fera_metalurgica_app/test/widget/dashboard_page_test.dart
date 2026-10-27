import 'dart:async';

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

import '../mocks/mock_cronograma_repository.dart';
import '../mocks/mock_orcamento_repository.dart';

/// Um orçamento do seed com [id], [status] e [dia] (de agosto) trocados.
Orcamento _orcamento(String id, StatusOrcamento status, int dia) =>
    orcamentosSeed.first.copyWith(
      id: id,
      status: status,
      criadoEm: DateTime(2026, 8, dia),
    );

/// Contagens diferentes em cada card: 3 em análise, 2 enviados, 1
/// aprovado, além de um rascunho e um recusado que não contam (D-03).
final List<Orcamento> _orcamentos = [
  _orcamento('00490', StatusOrcamento.rascunho, 30),
  _orcamento('00489', StatusOrcamento.recusado, 29),
  _orcamento('00488', StatusOrcamento.emAnalise, 28),
  _orcamento('00487', StatusOrcamento.emAnalise, 27),
  _orcamento('00486', StatusOrcamento.emAnalise, 26),
  _orcamento('00485', StatusOrcamento.enviado, 25),
  _orcamento('00484', StatusOrcamento.enviado, 24),
  _orcamento('00483', StatusOrcamento.aprovado, 23),
];

/// 4 tarefas de produção pendentes, mais uma concluída e uma de outro
/// tipo, que não contam.
final List<Tarefa> _tarefas = [
  for (var i = 0; i < 4; i++) cronogramaSeed.last.copyWith(id: 'producao-$i'),
  cronogramaSeed.last.copyWith(id: 'concluida', concluida: true),
  cronogramaSeed.first,
];

void main() {
  late MockOrcamentoRepository orcamentos;
  late MockCronogramaRepository tarefas;

  setUp(() {
    orcamentos = MockOrcamentoRepository();
    tarefas = MockCronogramaRepository();
    when(() => orcamentos.getAll()).thenAnswer((_) async => _orcamentos);
    when(() => tarefas.getAll()).thenAnswer((_) async => _tarefas);
  });

  /// Monta o dashboard num router mínimo: wizard, lista e detalhes viram
  /// textos, para conferir a navegação sem abrir as telas de outras
  /// trilhas.
  Future<void> abrirDashboard(
    WidgetTester tester, {
    ThemeMode themeMode = ThemeMode.light,
    bool aguardar = true,
  }) async {
    tester.view
      ..physicalSize = const Size(800, 2400)
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
          cronogramaRepositoryProvider.overrideWithValue(tarefas),
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

  testWidgets('mostra o CTA, os 4 indicadores e as contagens (D-03)', (
    tester,
  ) async {
    await abrirDashboard(tester);

    expect(find.text('Criar orçamento'), findsOneWidget);
    expect(valorDoCard(tester, 'Orçamentos em andamento'), '03');
    expect(valorDoCard(tester, 'Aguardando aprovação'), '02');
    expect(valorDoCard(tester, 'Aprovados'), '01');
    expect(valorDoCard(tester, 'Pedidos em produção'), '04');
    expect(find.text('03'), findsOneWidget);
    expect(find.text('04'), findsOneWidget);
  });

  testWidgets('mostra só os 2 recentes, sem rascunho e com recusado', (
    tester,
  ) async {
    await abrirDashboard(tester);

    expect(find.text('Orçamentos Recentes'), findsOneWidget);
    expect(find.byType(OrcamentoRecenteCard), findsNWidgets(2));
    expect(find.text('#00490'), findsNothing);
    expect(find.textContaining('#00489'), findsOneWidget);
    expect(find.textContaining('#00488'), findsOneWidget);
    expect(find.textContaining('29/08/2026'), findsOneWidget);
    expect(find.text('Recusado'), findsOneWidget);
    expect(find.text('Em análise'), findsOneWidget);
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

    expect(find.text('detalhes 00489'), findsOneWidget);
  });

  testWidgets('mostra o carregamento enquanto os dados não chegam', (
    tester,
  ) async {
    final pendente = Completer<List<Orcamento>>();
    when(() => orcamentos.getAll()).thenAnswer((_) => pendente.future);

    await abrirDashboard(tester, aguardar: false);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Criar orçamento'), findsOneWidget);
    expect(find.byType(StatCard), findsNothing);

    pendente.complete(_orcamentos);
    await tester.pumpAndSettle();
    expect(find.byType(StatCard), findsNWidgets(4));
  });

  testWidgets('sem dados: cards em 00, aviso nos recentes e CTA visível', (
    tester,
  ) async {
    when(() => orcamentos.getAll()).thenAnswer((_) async => []);
    when(() => tarefas.getAll()).thenAnswer((_) async => []);

    await abrirDashboard(tester);

    expect(find.text('00'), findsNWidgets(4));
    expect(find.text('Nenhum orçamento ainda.'), findsOneWidget);
    expect(find.byType(OrcamentoRecenteCard), findsNothing);
    expect(find.text('Criar orçamento'), findsOneWidget);
  });

  testWidgets('só rascunhos: recentes vazios e cards em 00', (tester) async {
    when(() => orcamentos.getAll()).thenAnswer(
      (_) async => [_orcamento('00490', StatusOrcamento.rascunho, 30)],
    );
    when(() => tarefas.getAll()).thenAnswer((_) async => []);

    await abrirDashboard(tester);

    expect(find.text('00'), findsNWidgets(4));
    expect(find.text('Nenhum orçamento ainda.'), findsOneWidget);
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
}
