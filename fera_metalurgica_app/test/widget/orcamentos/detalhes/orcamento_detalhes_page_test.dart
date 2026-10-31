import 'dart:async';

import 'package:fera_metalurgica_app/core/di/banco_de_dados.dart';
import 'package:fera_metalurgica_app/core/di/relogio_provider.dart';
import 'package:fera_metalurgica_app/core/router/app_routes.dart';
import 'package:fera_metalurgica_app/core/theme/app_theme.dart';
import 'package:fera_metalurgica_app/features/cronograma/cronograma.dart';
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
    Size tamanho = const Size(800, 3000),
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
          builder: (_, _) => const Scaffold(body: Text('lista')),
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
    // Empilhado sobre a lista, para o "voltar" ter para onde ir.
    unawaited(router.push(AppRoutes.detalhesOrcamento(id)));
    await tester.pumpAndSettle();
  }

  Future<Orcamento?> salvo(String id) =>
      SqliteOrcamentoRepository(banco).buscarPorId(id);

  Future<void> tocarNoMenu(WidgetTester tester, String opcao) async {
    await tester.tap(find.byTooltip('Mais opções'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(opcao));
    await tester.pumpAndSettle();
  }

  Finder noDialogo(String texto) =>
      find.descendant(of: find.byType(AlertDialog), matching: find.text(texto));

  for (final modo in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('renderiza o exemplo C com os totais gravados (${modo.name})', (
      tester,
    ) async {
      await abrirDetalhes(tester, 'orcamento-c', themeMode: modo);

      expect(find.text('071023-01'), findsOneWidget);
      expect(find.text('Criado'), findsOneWidget);
      expect(find.text('Ainda não enviado'), findsOneWidget);
      expect(find.text('Nº 071023-01'), findsOneWidget);
      expect(find.text('Emissão: 07/10/2023'), findsOneWidget);
      expect(find.text('Válido até 22/10/2023'), findsOneWidget);
      expect(find.text('João da Silva'), findsOneWidget);

      // Produtos com quantidade, preço unitário e total (D-39).
      expect(find.text('Mesa de jantar sob medida'), findsOneWidget);
      expect(find.text(r'2 × R$ 1.353,20'), findsOneWidget);
      expect(find.text(r'R$ 2.706,40'), findsOneWidget);
      expect(find.text('Painel em MDF'), findsOneWidget);
      expect(find.text(r'3 × R$ 214,80'), findsOneWidget);
      expect(find.text(r'R$ 644,40'), findsOneWidget);

      // Totais gravados, na ordem da D-39.
      for (final (rotulo, valor) in [
        ('Total dos produtos', r'R$ 3.350,80'),
        ('Insumos', r'R$ 100,00'),
        ('Impostos', r'R$ 200,00'),
        ('Combustível', r'R$ 50,00'),
        ('Outros: Frete', r'R$ 30,00'),
        ('Subtotal', r'R$ 3.730,80'),
        ('Desconto', r'− R$ 100,00'),
      ]) {
        expect(find.text(rotulo), findsOneWidget, reason: rotulo);
        expect(find.text(valor), findsOneWidget, reason: rotulo);
      }
      expect(find.text('Total geral'), findsOneWidget);
      // Só no card "Totais": o card das ações não repete o total.
      expect(find.text(r'R$ 3.630,80'), findsOneWidget);
      expect(
        find.text('Prazo de entrega a combinar na aprovação.'),
        findsOneWidget,
      );

      expect(find.text('Enviar WhatsApp'), findsOneWidget);
      expect(find.text('Gerar PDF'), findsOneWidget);
      expect(find.text('Editar'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'as peças e os custos começam recolhidos e abrem no interruptor',
    (tester) async {
      await abrirDetalhes(tester, 'orcamento-c');

      // Tampo: R$ 486,00; pernas: R$ 67,20; materiais da mesa: R$ 553,20.
      expect(find.text('PEÇAS (USO INTERNO)'), findsNothing);
      for (final valor in ['486,00', '67,20', '553,20']) {
        expect(find.textContaining(valor), findsNothing);
      }

      await tester.tap(find.text('Mostrar peças e custos'));
      await tester.pumpAndSettle();

      expect(find.text('PEÇAS (USO INTERNO)'), findsNWidgets(2));
      for (final valor in ['486,00', '67,20', '553,20']) {
        expect(find.textContaining(valor), findsWidgets, reason: valor);
      }
    },
  );

  testWidgets('sem validade, não mostra a linha', (tester) async {
    await abrirDetalhes(tester, 'orcamento-b');

    expect(find.text('Construtora Horizonte Ltda'), findsOneWidget);
    expect(find.textContaining('Válido até'), findsNothing);
  });

  testWidgets('a 2ª revisão mostra "rev. N", o envio e a criação', (
    tester,
  ) async {
    await abrirDetalhes(tester, 'orcamento-e');

    expect(find.text('Nº 051023-02 rev. 2'), findsOneWidget);
    expect(find.text('051023-02 rev. 2'), findsOneWidget);
    expect(find.text('Enviado'), findsOneWidget);
    expect(find.text('Enviado em 09/10/2023'), findsOneWidget);
    expect(find.text('Criado em 05/10/2023'), findsOneWidget);
  });

  testWidgets('id inexistente mostra "não encontrado" e volta', (tester) async {
    await abrirDetalhes(tester, 'nao-existe');

    expect(find.text('Orçamento não encontrado'), findsOneWidget);

    await tester.tap(find.text('Voltar'));
    await tester.pumpAndSettle();

    expect(find.text('lista'), findsOneWidget);
  });

  testWidgets('"Marcar como enviado" muda o status sem confirmar (D-29)', (
    tester,
  ) async {
    await abrirDetalhes(tester, 'orcamento-c');

    await tocarNoMenu(tester, 'Marcar como enviado');

    expect(find.byType(AlertDialog), findsNothing);
    final orcamento = (await salvo('orcamento-c'))!;
    expect(orcamento.status, StatusOrcamento.enviado);
    expect(orcamento.enviadoEm, agoraDosExemplos);
    expect(orcamento.atualizadoEm, orcamentoExemploC.atualizadoEm);
    expect(find.text('Enviado'), findsOneWidget);
    expect(find.text('Enviado em 09/10/2023'), findsOneWidget);
  });

  testWidgets('"Voltar para criado" confirma antes e limpa o envio (D-37)', (
    tester,
  ) async {
    await abrirDetalhes(tester, 'orcamento-e');

    await tocarNoMenu(tester, 'Voltar para criado');
    expect(noDialogo('Voltar para criado?'), findsOneWidget);
    expect(
      find.textContaining('perde a data de envio (09/10/2023)'),
      findsOneWidget,
    );
    await tester.tap(noDialogo('Cancelar'));
    await tester.pumpAndSettle();
    expect(await salvo('orcamento-e'), orcamentoExemploEnviado);

    await tocarNoMenu(tester, 'Voltar para criado');
    await tester.tap(noDialogo('Voltar para criado'));
    await tester.pumpAndSettle();

    final orcamento = (await salvo('orcamento-e'))!;
    expect(orcamento.status, StatusOrcamento.criado);
    expect(orcamento.enviadoEm, isNull);
    expect(orcamento.atualizadoEm, orcamentoExemploEnviado.atualizadoEm);
    expect(find.text('Ainda não enviado'), findsOneWidget);
  });

  testWidgets('"Excluir" confirma, exclui e volta à tela anterior', (
    tester,
  ) async {
    await abrirDetalhes(tester, 'orcamento-c');

    await tocarNoMenu(tester, 'Excluir');
    expect(noDialogo('Excluir o orçamento?'), findsOneWidget);
    await tester.tap(noDialogo('Cancelar'));
    await tester.pumpAndSettle();
    expect(await salvo('orcamento-c'), isNotNull);
    expect(find.text('Nº 071023-01'), findsOneWidget);

    await tocarNoMenu(tester, 'Excluir');
    await tester.tap(noDialogo('Excluir'));
    await tester.pumpAndSettle();

    expect(await salvo('orcamento-c'), isNull);
    expect(find.text('lista'), findsOneWidget);
    expect(find.text('Orçamento 071023-01 excluído.'), findsOneWidget);
  });

  testWidgets('excluir mantém a tarefa na agenda, sem o vínculo (D-38)', (
    tester,
  ) async {
    final tarefa = Tarefa(
      id: 'tarefa-c',
      titulo: 'Produção 071023-01',
      data: DateTime(2023, 10, 12, 9),
      tipo: TipoTarefa.producao,
      orcamentoId: 'orcamento-c',
    );
    await SqliteTarefaRepository(banco).save(tarefa);
    await abrirDetalhes(tester, 'orcamento-c');

    final container = ProviderScope.containerOf(
      tester.element(find.byType(OrcamentoDetalhesPage)),
    );
    // A agenda já carregada guarda o vínculo antigo até ser recarregada.
    final assinatura = container.listen(tarefasProvider, (_, _) {});
    addTearDown(assinatura.close);
    expect(
      (await container.read(tarefasProvider.future)).single.orcamentoId,
      'orcamento-c',
    );

    await tocarNoMenu(tester, 'Excluir');
    await tester.tap(noDialogo('Excluir'));
    await tester.pumpAndSettle();

    final tarefas = await container.read(tarefasProvider.future);
    expect(tarefas, [tarefa.copyWith(orcamentoId: null)]);
  });

  testWidgets('posiciona as tarefas do orçamento e o "Agendar" (V2-E)', (
    tester,
  ) async {
    await abrirDetalhes(tester, 'orcamento-c');

    final tarefas = tester.widget<TarefasDoOrcamento>(
      find.byType(TarefasDoOrcamento),
    );
    final agendar = tester.widget<AgendarTarefaButton>(
      find.byType(AgendarTarefaButton),
    );
    expect(tarefas.orcamentoId, 'orcamento-c');
    expect(agendar.orcamentoId, 'orcamento-c');
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

  for (final modo in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('cabe em 360 dp, com as peças abertas (${modo.name})', (
      tester,
    ) async {
      await abrirDetalhes(
        tester,
        'orcamento-c',
        themeMode: modo,
        tamanho: const Size(360, 800),
      );
      await tester.tap(find.text('Mostrar peças e custos'));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, -3000));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  }
}
