import 'package:fera_metalurgica_app/core/router/app_routes.dart';
import 'package:fera_metalurgica_app/core/theme/app_theme.dart';
import 'package:fera_metalurgica_app/core/widgets/filter_chips_bar.dart';
import 'package:fera_metalurgica_app/features/orcamentos/orcamentos.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/lista/orcamento_list_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/mock_orcamento_repository.dart';

void main() {
  late MockOrcamentoRepository repository;

  setUp(() {
    repository = MockOrcamentoRepository();
    when(() => repository.getAll()).thenAnswer((_) async => orcamentosSeed);
  });

  /// Monta a lista num router mínimo: wizard e detalhes viram textos, para
  /// conferir a navegação sem abrir as telas das outras trilhas.
  Future<void> abrirLista(
    WidgetTester tester, {
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    tester.view
      ..physicalSize = const Size(800, 2400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: AppRoutes.orcamentos,
      routes: [
        GoRoute(
          path: AppRoutes.orcamentos,
          builder: (_, _) => const OrcamentosListaPage(),
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
        overrides: [orcamentoRepositoryProvider.overrideWithValue(repository)],
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

  Finder cartoes() => find.byType(OrcamentoListCard);

  Finder noCartao(String texto) =>
      find.descendant(of: cartoes(), matching: find.text(texto));

  for (final modo in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('renderiza os orçamentos do seed (${modo.name})', (
      tester,
    ) async {
      await abrirLista(tester, themeMode: modo);

      expect(find.text('Orçamentos'), findsOneWidget);
      expect(find.text('Buscar por cliente ou número...'), findsOneWidget);
      expect(cartoes(), findsNWidgets(orcamentosSeed.length));

      expect(find.text('#00482'), findsOneWidget);
      expect(find.text('João da Silva'), findsOneWidget);
      expect(noCartao('Em análise'), findsOneWidget);
      expect(find.text('17/08/2026'), findsOneWidget);
      expect(find.text(r'R$ 8.450,00'), findsOneWidget);
      expect(find.text(r'R$ 12.300,00'), findsOneWidget);

      // Só o rascunho (#00480) mostra "Valor Estimado".
      expect(find.text('Valor Estimado'), findsOneWidget);
      expect(find.text('Valor Total'), findsNWidgets(4));
      expect(noCartao('Rascunho'), findsOneWidget);
    });
  }

  testWidgets('mostra os chips de D-22 na ordem', (tester) async {
    await abrirLista(tester);

    final chips = [
      'Todos',
      'Rascunhos',
      'Em análise',
      'Enviados',
      'Aprovados',
      'Recusados',
    ];
    final xs = [
      for (final chip in chips)
        tester
            .getTopLeft(
              find.descendant(
                of: find.byType(FilterChipsBar),
                matching: find.text(chip),
              ),
            )
            .dx,
    ];
    expect(xs, [...xs]..sort());
  });

  testWidgets('filtra por status', (tester) async {
    await abrirLista(tester);

    await tester.tap(find.text('Aprovados'));
    await tester.pumpAndSettle();
    expect(cartoes(), findsOneWidget);
    expect(find.text('Metalúrgica ABC Ltda'), findsOneWidget);

    await tester.tap(find.text('Rascunhos'));
    await tester.pumpAndSettle();
    expect(cartoes(), findsOneWidget);
    expect(find.text('Construtora Nova Era'), findsOneWidget);

    await tester.tap(find.text('Todos'));
    await tester.pumpAndSettle();
    expect(cartoes(), findsNWidgets(orcamentosSeed.length));
  });

  testWidgets('busca por nome sem acento', (tester) async {
    await abrirLista(tester);

    await tester.enterText(find.byType(TextField), 'metalurgica');
    await tester.pumpAndSettle();

    expect(cartoes(), findsOneWidget);
    expect(find.text('Metalúrgica ABC Ltda'), findsOneWidget);
  });

  testWidgets('busca por número', (tester) async {
    await abrirLista(tester);

    await tester.enterText(find.byType(TextField), '#00479');
    await tester.pumpAndSettle();

    expect(cartoes(), findsOneWidget);
    expect(find.text('Construtora Apex'), findsOneWidget);
  });

  testWidgets('busca sem resultado mostra o estado vazio com "Novo"', (
    tester,
  ) async {
    await abrirLista(tester);

    await tester.enterText(find.byType(TextField), 'inexistente');
    await tester.pumpAndSettle();

    expect(cartoes(), findsNothing);
    expect(find.text('Nenhum orçamento encontrado'), findsOneWidget);
    expect(find.text('Novo'), findsNWidgets(2));
  });

  testWidgets('sem orçamentos mostra o estado vazio', (tester) async {
    when(() => repository.getAll()).thenAnswer((_) async => []);
    await abrirLista(tester);

    expect(find.text('Nenhum orçamento encontrado'), findsOneWidget);
  });

  testWidgets('erro ao carregar permite tentar novamente', (tester) async {
    when(() => repository.getAll()).thenThrow(Exception('falha'));
    await abrirLista(tester);

    expect(
      find.text('Não foi possível carregar os orçamentos.'),
      findsOneWidget,
    );

    when(() => repository.getAll()).thenAnswer((_) async => orcamentosSeed);
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();

    expect(cartoes(), findsNWidgets(orcamentosSeed.length));
  });

  testWidgets('tocar no cartão abre os detalhes', (tester) async {
    await abrirLista(tester);

    await tester.tap(find.text('Metalúrgica ABC Ltda'));
    await tester.pumpAndSettle();

    expect(find.text('detalhes 00481'), findsOneWidget);
  });

  testWidgets('"Novo" abre o wizard', (tester) async {
    await abrirLista(tester);

    await tester.tap(find.text('Novo'));
    await tester.pumpAndSettle();

    expect(find.text('wizard'), findsOneWidget);
  });
}
