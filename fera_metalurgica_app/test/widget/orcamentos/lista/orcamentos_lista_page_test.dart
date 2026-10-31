import 'package:fera_metalurgica_app/core/di/banco_de_dados.dart';
import 'package:fera_metalurgica_app/core/router/app_routes.dart';
import 'package:fera_metalurgica_app/core/theme/app_theme.dart';
import 'package:fera_metalurgica_app/core/widgets/filter_chips_bar.dart';
import 'package:fera_metalurgica_app/features/orcamentos/orcamentos.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/lista/orcamento_list_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/container_de_teste.dart';
import '../../../mocks/dados_exemplo.dart';
import '../../../mocks/mock_orcamento_repository.dart';

void main() {
  /// Monta a lista num router mínimo: wizard e detalhes viram textos, para
  /// conferir a navegação sem abrir as telas das outras trilhas.
  Future<void> abrirLista(
    WidgetTester tester, {
    ThemeMode themeMode = ThemeMode.light,
    List<Orcamento>? orcamentos,
    List<Override>? overrides,
    Size tamanho = const Size(800, 2400),
  }) async {
    tester.view
      ..physicalSize = tamanho
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

    final banco = await bancoComOrcamentos(orcamentos ?? orcamentosExemplo);
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides ?? [bancoDeDadosProvider.overrideWithValue(banco)],
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
    testWidgets('renderiza os orçamentos salvos (${modo.name})', (
      tester,
    ) async {
      await abrirLista(tester, themeMode: modo);

      expect(find.text('Orçamentos'), findsOneWidget);
      expect(find.text('Buscar por cliente ou código...'), findsOneWidget);
      expect(cartoes(), findsNWidgets(3));

      expect(find.text('071023-01'), findsOneWidget);
      expect(find.text('051023-02 rev. 2'), findsOneWidget);
      expect(find.text('João da Silva'), findsOneWidget);
      expect(find.text('07/10/2023'), findsOneWidget);
      expect(find.text(r'R$ 3.630,80'), findsOneWidget);
      expect(find.text(r'R$ 644,40'), findsNWidgets(2));
      expect(noCartao('Criado'), findsNWidgets(2));
      expect(noCartao('Enviado'), findsOneWidget);
    });
  }

  testWidgets('mostra os chips Todos, Criados e Enviados (D-29)', (
    tester,
  ) async {
    await abrirLista(tester);

    final xs = [
      for (final chip in ['Todos', 'Criados', 'Enviados'])
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

    await tester.tap(find.text('Enviados'));
    await tester.pumpAndSettle();
    expect(cartoes(), findsOneWidget);
    expect(find.text('Metalúrgica ABC Ltda'), findsOneWidget);

    await tester.tap(find.text('Criados'));
    await tester.pumpAndSettle();
    expect(cartoes(), findsNWidgets(2));

    await tester.tap(find.text('Todos'));
    await tester.pumpAndSettle();
    expect(cartoes(), findsNWidgets(3));
  });

  testWidgets('busca por nome sem acento', (tester) async {
    await abrirLista(tester);

    await tester.enterText(find.byType(TextField), 'metalurgica');
    await tester.pumpAndSettle();

    expect(cartoes(), findsOneWidget);
    expect(find.text('Metalúrgica ABC Ltda'), findsOneWidget);
  });

  testWidgets('busca por código', (tester) async {
    await abrirLista(tester);

    await tester.enterText(find.byType(TextField), '081023-01');
    await tester.pumpAndSettle();

    expect(cartoes(), findsOneWidget);
    expect(find.text('Construtora Horizonte Ltda'), findsOneWidget);
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
    await abrirLista(tester, orcamentos: const []);

    expect(find.text('Nenhum orçamento encontrado'), findsOneWidget);
  });

  testWidgets('erro ao carregar permite tentar novamente', (tester) async {
    final repository = MockOrcamentoRepository();
    when(repository.listarResumos).thenThrow(Exception('falha'));
    await abrirLista(
      tester,
      overrides: [orcamentoRepositoryProvider.overrideWithValue(repository)],
    );

    expect(
      find.text('Não foi possível carregar os orçamentos.'),
      findsOneWidget,
    );

    when(repository.listarResumos).thenAnswer((_) async => orcamentosExemplo);
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();

    expect(cartoes(), findsNWidgets(3));
  });

  testWidgets('tocar no cartão abre os detalhes', (tester) async {
    await abrirLista(tester);

    await tester.tap(find.text('Metalúrgica ABC Ltda'));
    await tester.pumpAndSettle();

    expect(find.text('detalhes orcamento-e'), findsOneWidget);
  });

  testWidgets('"Novo" abre o wizard', (tester) async {
    await abrirLista(tester);

    await tester.tap(find.text('Novo'));
    await tester.pumpAndSettle();

    expect(find.text('wizard'), findsOneWidget);
  });

  testWidgets('o cartão mostra a data da revisão atual (HO-V2-F2-04)', (
    tester,
  ) async {
    await abrirLista(tester);

    // O enviado foi criado em 05/10 (o código) e revisado em 09/10.
    final cartao = find.ancestor(
      of: find.text('051023-02 rev. 2'),
      matching: cartoes(),
    );
    expect(
      find.descendant(of: cartao, matching: find.text('09/10/2023')),
      findsOneWidget,
    );
    expect(find.text('05/10/2023'), findsNothing);
  });

  for (final modo in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('cabe em 360 dp sem overflow (${modo.name})', (tester) async {
      await abrirLista(tester, themeMode: modo, tamanho: const Size(360, 800));

      expect(tester.takeException(), isNull);
      expect(cartoes(), findsWidgets);
    });
  }
}
