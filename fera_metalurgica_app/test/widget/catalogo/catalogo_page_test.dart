import 'package:fera_metalurgica_app/core/router/app_routes.dart';
import 'package:fera_metalurgica_app/core/theme/app_theme.dart';
import 'package:fera_metalurgica_app/core/widgets/app_top_bar.dart';
import 'package:fera_metalurgica_app/core/widgets/filter_chips_bar.dart';
import 'package:fera_metalurgica_app/features/catalogo/catalogo.dart';
import 'package:fera_metalurgica_app/features/catalogo/presentation/produto_card.dart';
import 'package:fera_metalurgica_app/features/catalogo/presentation/produto_detalhes_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks/mock_catalogo_repository.dart';

void main() {
  late MockCatalogoRepository repository;

  setUp(() {
    repository = MockCatalogoRepository();
    when(() => repository.getAll()).thenAnswer((_) async => catalogoSeed);
  });

  /// Monta o catálogo num router mínimo: o wizard vira um texto com o
  /// `produtoId` recebido, para conferir a navegação sem abrir a tela da T3.
  Future<void> abrirCatalogo(
    WidgetTester tester, {
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    tester.view
      ..physicalSize = const Size(800, 2400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: AppRoutes.catalogo,
      routes: [
        GoRoute(
          path: AppRoutes.catalogo,
          builder: (_, _) => const CatalogoPage(),
        ),
        GoRoute(
          path: AppRoutes.novoOrcamento(),
          builder: (_, state) =>
              Text('wizard ${state.uri.queryParameters['produtoId']}'),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [catalogoRepositoryProvider.overrideWithValue(repository)],
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

  Finder cartoes() => find.byType(ProdutoCard);

  Finder chip(String label) => find.descendant(
    of: find.byType(FilterChipsBar),
    matching: find.text(label),
  );

  for (final modo in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('renderiza os produtos do seed (${modo.name})', (tester) async {
      await abrirCatalogo(tester, themeMode: modo);

      expect(find.text('Catálogo de Produtos'), findsOneWidget);
      expect(
        find.textContaining('Selecione os itens desejados'),
        findsOneWidget,
      );
      expect(cartoes(), findsNWidgets(catalogoSeed.length));
      for (final produto in catalogoSeed) {
        expect(find.text(produto.nome), findsOneWidget);
        expect(find.text(produto.descricaoTecnica), findsOneWidget);
      }
      // As fotos do seed existem em assets/images/catalogo/.
      expect(
        find.byKey(const ValueKey('produto-foto-placeholder')),
        findsNothing,
      );
    });
  }

  testWidgets('top bar sem voltar, por ser raiz de aba', (tester) async {
    await abrirCatalogo(tester);

    expect(find.byType(AppTopBar), findsOneWidget);
    expect(find.byTooltip('Voltar'), findsNothing);
  });

  testWidgets('chips: "Todos" e as categorias em ordem alfabética', (
    tester,
  ) async {
    await abrirCatalogo(tester);

    final labels = tester
        .widget<FilterChipsBar>(find.byType(FilterChipsBar))
        .opcoes;
    expect(labels, ['Todos', 'Estruturas', 'Grades', 'Portões']);
  });

  testWidgets('filtro por categoria reduz a lista e "Todos" volta', (
    tester,
  ) async {
    await abrirCatalogo(tester);

    await tester.tap(chip('Grades'));
    await tester.pumpAndSettle();

    expect(cartoes(), findsOneWidget);
    expect(find.text('Grade de Proteção Pesada'), findsOneWidget);
    expect(find.text('Portão Basculante'), findsNothing);

    await tester.tap(chip('Todos'));
    await tester.pumpAndSettle();

    expect(cartoes(), findsNWidgets(catalogoSeed.length));
  });

  testWidgets('tocar no cartão abre a folha com os detalhes', (tester) async {
    await abrirCatalogo(tester);

    await tester.tap(find.text('Estrutura Treliçada'));
    await tester.pumpAndSettle();

    final sheet = find.byType(ProdutoDetalhesSheet);
    expect(sheet, findsOneWidget);
    for (final texto in [
      'Estrutura Treliçada',
      'Estruturas',
      catalogoSeed[1].descricaoTecnica,
      'Usar no orçamento',
    ]) {
      expect(
        find.descendant(of: sheet, matching: find.text(texto)),
        findsOneWidget,
      );
    }
  });

  testWidgets('"Usar no orçamento" fecha a folha e abre o wizard', (
    tester,
  ) async {
    await abrirCatalogo(tester);

    await tester.tap(find.text('Estrutura Treliçada'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Usar no orçamento'));
    await tester.pumpAndSettle();

    expect(find.byType(ProdutoDetalhesSheet), findsNothing);
    expect(find.text('wizard produto-estrutura-trelicada'), findsOneWidget);
  });

  testWidgets('fechar a folha sem escolher não navega', (tester) async {
    await abrirCatalogo(tester);

    await tester.tap(find.text('Portão Basculante'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(400, 20));
    await tester.pumpAndSettle();

    expect(find.byType(ProdutoDetalhesSheet), findsNothing);
    expect(find.textContaining('wizard'), findsNothing);
    expect(cartoes(), findsNWidgets(catalogoSeed.length));
  });

  testWidgets('catálogo vazio mostra o estado vazio', (tester) async {
    when(() => repository.getAll()).thenAnswer((_) async => []);
    await abrirCatalogo(tester);

    expect(find.text('Nenhum produto no catálogo'), findsOneWidget);
    expect(cartoes(), findsNothing);
  });

  testWidgets('erro ao carregar permite tentar novamente', (tester) async {
    when(() => repository.getAll()).thenThrow(Exception('falha'));
    await abrirCatalogo(tester);

    expect(find.text('Não foi possível carregar o catálogo.'), findsOneWidget);

    when(() => repository.getAll()).thenAnswer((_) async => catalogoSeed);
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();

    expect(cartoes(), findsNWidgets(catalogoSeed.length));
  });

  testWidgets('produto sem foto mostra o placeholder', (tester) async {
    when(
      () => repository.getAll(),
    ).thenAnswer((_) async => [catalogoSeed.first.copyWith(fotoPath: null)]);
    await abrirCatalogo(tester);

    expect(
      find.byKey(const ValueKey('produto-foto-placeholder')),
      findsOneWidget,
    );
  });

  testWidgets('foto inexistente cai no placeholder', (tester) async {
    when(() => repository.getAll()).thenAnswer(
      (_) async => [
        catalogoSeed.first.copyWith(fotoPath: 'assets/images/catalogo/x.jpg'),
      ],
    );
    await abrirCatalogo(tester);

    expect(
      find.byKey(const ValueKey('produto-foto-placeholder')),
      findsOneWidget,
    );
  });
}
