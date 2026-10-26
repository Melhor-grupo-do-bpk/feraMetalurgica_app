import 'package:fera_metalurgica_app/core/router/app_routes.dart';
import 'package:fera_metalurgica_app/core/theme/app_theme.dart';
import 'package:fera_metalurgica_app/core/utils/currency_format.dart';
import 'package:fera_metalurgica_app/features/orcamentos/orcamentos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/mock_orcamento_repository.dart';

void main() {
  late MockOrcamentoRepository repository;

  setUpAll(() => registerFallbackValue(orcamentosSeed.first));

  setUp(() {
    repository = MockOrcamentoRepository();
    when(() => repository.getAll()).thenAnswer((_) async => orcamentosSeed);
    when(() => repository.save(any())).thenAnswer((_) async {});
  });

  /// Abre os detalhes de [id] por cima de uma "lista" de mentira; editar e
  /// PDF viram textos, para conferir a navegação sem as outras trilhas.
  Future<void> abrirDetalhes(
    WidgetTester tester,
    String id, {
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    tester.view
      ..physicalSize = const Size(800, 2400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: AppRoutes.detalhesOrcamento(id),
      routes: [
        GoRoute(
          path: AppRoutes.orcamentos,
          builder: (_, _) => const Text('lista'),
          routes: [
            GoRoute(
              path: ':id',
              builder: (_, state) => OrcamentoDetalhesPage(
                orcamentoId: state.pathParameters['id']!,
              ),
              routes: [
                GoRoute(
                  path: 'editar',
                  builder: (_, state) =>
                      Text('editar ${state.pathParameters['id']}'),
                ),
                GoRoute(
                  path: 'pdf',
                  builder: (_, state) =>
                      Text('pdf ${state.pathParameters['id']}'),
                ),
              ],
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

  for (final modo in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('renderiza o orçamento #00482 (${modo.name})', (tester) async {
      await abrirDetalhes(tester, '00482', themeMode: modo);

      expect(find.text('João da Silva'), findsOneWidget);
      expect(find.text('Cliente PF'), findsOneWidget);
      expect(find.text('#00482'), findsOneWidget);
      expect(find.text('17/08/2026'), findsOneWidget);
      expect(find.text('15 dias úteis'), findsOneWidget);
      expect(find.text('15 dias'), findsOneWidget);

      expect(find.text('Itens do Orçamento'), findsOneWidget);
      expect(find.text('Portão metálico basculante'), findsOneWidget);
      expect(find.text('2.50m x 2.20m • Aço Carbono'), findsOneWidget);
      expect(find.text('Estrutura tubular 50×50mm, chapa 18'), findsOneWidget);
      expect(find.text('Qtd: 1 un'), findsOneWidget);

      expect(find.text('Valor Final'), findsOneWidget);
      expect(find.text(r'R$ 8.450,00'), findsOneWidget);
      expect(find.text('Enviar WhatsApp'), findsOneWidget);
      expect(find.text('Gerar PDF'), findsOneWidget);
      expect(find.text('Editar'), findsOneWidget);
    });
  }

  testWidgets('não mostra custos internos nem preço por item', (tester) async {
    await abrirDetalhes(tester, '00482');

    // O único valor em reais na tela é o valor final (D-01, D-16).
    expect(find.textContaining(r'R$'), findsOneWidget);
    final custos = orcamentosSeed.first.custosOperacionais;
    for (final valor in [
      custos.materiaPrima,
      custos.maoDeObra,
      custos.insumos,
      custos.combustivel,
      custos.impostos,
      calcularTotalCustos(custos),
    ]) {
      expect(find.textContaining(formatarNumeroMoeda(valor)), findsNothing);
    }
    expect(find.textContaining('Matéria'), findsNothing);
    expect(find.textContaining('Custo'), findsNothing);
  });

  testWidgets('cliente com CNPJ aparece como PJ', (tester) async {
    await abrirDetalhes(tester, '00481');

    expect(find.text('Metalúrgica ABC Ltda'), findsOneWidget);
    expect(find.text('Cliente PJ'), findsOneWidget);
  });

  testWidgets('id inexistente mostra "não encontrado" e volta', (tester) async {
    await abrirDetalhes(tester, '99999');

    expect(find.text('Orçamento não encontrado'), findsOneWidget);

    await tester.tap(find.text('Voltar'));
    await tester.pumpAndSettle();

    expect(find.text('lista'), findsOneWidget);
  });

  testWidgets('"Alterar status" salva o status escolhido', (tester) async {
    await abrirDetalhes(tester, '00482');

    await tester.tap(find.byTooltip('Mais opções'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alterar status'));
    await tester.pumpAndSettle();

    // D-06: os 4 status, sem rascunho.
    final dialogo = find.byType(SimpleDialog);
    for (final status in ['Em análise', 'Enviado', 'Aprovado', 'Recusado']) {
      expect(
        find.descendant(of: dialogo, matching: find.text(status)),
        findsOneWidget,
      );
    }
    expect(
      find.descendant(of: dialogo, matching: find.text('Rascunho')),
      findsNothing,
    );

    await tester.tap(find.text('Aprovado'));
    await tester.pumpAndSettle();

    final salvo =
        verify(() => repository.save(captureAny())).captured.single
            as Orcamento;
    expect(salvo.id, '00482');
    expect(salvo.status, StatusOrcamento.aprovado);
    expect(find.byType(SimpleDialog), findsNothing);
  });

  testWidgets('escolher o status atual não salva', (tester) async {
    await abrirDetalhes(tester, '00482');

    await tester.tap(find.byTooltip('Mais opções'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alterar status'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Em análise'));
    await tester.pumpAndSettle();

    verifyNever(() => repository.save(any()));
  });

  testWidgets('"Editar" abre o wizard de edição', (tester) async {
    await abrirDetalhes(tester, '00482');

    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();

    expect(find.text('editar 00482'), findsOneWidget);
  });

  testWidgets('"Gerar PDF" abre a prévia do PDF', (tester) async {
    await abrirDetalhes(tester, '00482');

    await tester.tap(find.text('Gerar PDF'));
    await tester.pumpAndSettle();

    expect(find.text('pdf 00482'), findsOneWidget);
  });

  testWidgets('"Enviar WhatsApp" ainda não faz nada (T5)', (tester) async {
    await abrirDetalhes(tester, '00482');

    await tester.tap(find.text('Enviar WhatsApp'));
    await tester.pumpAndSettle();

    expect(find.byType(OrcamentoDetalhesPage), findsOneWidget);
    verifyNever(() => repository.save(any()));
  });
}
