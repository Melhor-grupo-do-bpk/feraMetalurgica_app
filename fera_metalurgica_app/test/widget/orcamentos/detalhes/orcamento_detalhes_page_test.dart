import 'package:fera_metalurgica_app/core/di/banco_de_dados.dart';
import 'package:fera_metalurgica_app/core/di/relogio_provider.dart';
import 'package:fera_metalurgica_app/core/router/app_routes.dart';
import 'package:fera_metalurgica_app/core/theme/app_theme.dart';
import 'package:fera_metalurgica_app/features/orcamentos/orcamentos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../mocks/container_de_teste.dart';
import '../../../mocks/dados_exemplo.dart';

void main() {
  late Database banco;

  setUp(() async => banco = await bancoComOrcamentos(orcamentosExemplo));

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
        overrides: [
          bancoDeDadosProvider.overrideWithValue(banco),
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
    await tester.pumpAndSettle();
  }

  Future<Orcamento> salvo(String id) async =>
      (await SqliteOrcamentoRepository(banco).buscarPorId(id))!;

  for (final modo in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('renderiza o exemplo C com os totais gravados (${modo.name})', (
      tester,
    ) async {
      await abrirDetalhes(tester, 'orcamento-c', themeMode: modo);

      expect(find.text('João da Silva'), findsOneWidget);
      expect(find.text('Cliente PF'), findsOneWidget);
      expect(find.text('071023-01'), findsOneWidget);
      expect(find.text('07/10/2023'), findsOneWidget);
      expect(find.text('22/10/2023'), findsOneWidget);

      expect(find.text('Itens do Orçamento'), findsOneWidget);
      expect(find.text('Mesa de jantar sob medida'), findsOneWidget);
      expect(find.text('1× Tampo • 4× Perna'), findsOneWidget);
      expect(find.text(r'Qtd: 2 × R$ 1.353,20 = R$ 2.706,40'), findsOneWidget);
      expect(find.text('Painel em MDF'), findsOneWidget);
      expect(find.text(r'Qtd: 3 × R$ 214,80 = R$ 644,40'), findsOneWidget);

      expect(find.text('Valor Final'), findsOneWidget);
      expect(find.text(r'R$ 3.630,80'), findsOneWidget);
      expect(find.text('Enviar WhatsApp'), findsOneWidget);
      expect(find.text('Gerar PDF'), findsOneWidget);
      expect(find.text('Editar'), findsOneWidget);
    });
  }

  testWidgets('não mostra o custo de material de cada peça (D-16)', (
    tester,
  ) async {
    await abrirDetalhes(tester, 'orcamento-c');

    // Tampo: R$ 486,00; pernas: R$ 67,20; materiais da mesa: R$ 553,20.
    for (final valor in ['486,00', '67,20', '553,20']) {
      expect(find.textContaining(valor), findsNothing);
    }
    expect(find.textContaining('Custo'), findsNothing);
  });

  testWidgets('sem validade, não mostra a linha', (tester) async {
    await abrirDetalhes(tester, 'orcamento-b');

    expect(find.text('Construtora Horizonte Ltda'), findsOneWidget);
    expect(find.text('Cliente PJ'), findsOneWidget);
    expect(find.text('Validade'), findsNothing);
  });

  testWidgets('a partir da 2ª revisão, mostra "rev. N"', (tester) async {
    await abrirDetalhes(tester, 'orcamento-e');

    expect(find.text('051023-02 rev. 2'), findsOneWidget);
  });

  testWidgets('id inexistente mostra "não encontrado" e volta', (tester) async {
    await abrirDetalhes(tester, 'nao-existe');

    expect(find.text('Orçamento não encontrado'), findsOneWidget);

    await tester.tap(find.text('Voltar'));
    await tester.pumpAndSettle();

    expect(find.text('lista'), findsOneWidget);
  });

  testWidgets('"Alterar status" alterna entre criado e enviado (D-29)', (
    tester,
  ) async {
    await abrirDetalhes(tester, 'orcamento-c');

    await tester.tap(find.byTooltip('Mais opções'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alterar status'));
    await tester.pumpAndSettle();

    final dialogo = find.byType(SimpleDialog);
    for (final status in ['Criado', 'Enviado']) {
      expect(
        find.descendant(of: dialogo, matching: find.text(status)),
        findsOneWidget,
      );
    }

    await tester.tap(
      find.descendant(of: dialogo, matching: find.text('Enviado')),
    );
    await tester.pumpAndSettle();

    final orcamento = await salvo('orcamento-c');
    expect(orcamento.status, StatusOrcamento.enviado);
    expect(orcamento.enviadoEm, agoraDosExemplos);
    expect(orcamento.atualizadoEm, orcamentoExemploC.atualizadoEm);
    expect(find.byType(SimpleDialog), findsNothing);
  });

  testWidgets('escolher o status atual não muda nada', (tester) async {
    await abrirDetalhes(tester, 'orcamento-c');

    await tester.tap(find.byTooltip('Mais opções'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alterar status'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Criado'));
    await tester.pumpAndSettle();

    expect(await salvo('orcamento-c'), orcamentoExemploC);
  });

  testWidgets('"Editar" abre o wizard de edição', (tester) async {
    await abrirDetalhes(tester, 'orcamento-c');

    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();

    expect(find.text('editar orcamento-c'), findsOneWidget);
  });

  testWidgets('"Gerar PDF" abre a prévia do PDF', (tester) async {
    await abrirDetalhes(tester, 'orcamento-c');

    await tester.tap(find.text('Gerar PDF'));
    await tester.pumpAndSettle();

    expect(find.text('pdf orcamento-c'), findsOneWidget);
  });
}
