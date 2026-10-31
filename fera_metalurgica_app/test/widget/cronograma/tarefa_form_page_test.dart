import 'dart:async';

import 'package:fera_metalurgica_app/core/di/relogio_provider.dart';
import 'package:fera_metalurgica_app/core/router/app_routes.dart';
import 'package:fera_metalurgica_app/core/theme/app_theme.dart';
import 'package:fera_metalurgica_app/features/cronograma/cronograma.dart';
import 'package:fera_metalurgica_app/features/orcamentos/orcamentos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks/dados_exemplo.dart';
import '../../mocks/mock_orcamento_repository.dart';
import '../../mocks/mock_tarefa_repository.dart';

void main() {
  late MockTarefaRepository tarefas;
  late MockOrcamentoRepository orcamentos;

  setUpAll(() => registerFallbackValue(tarefasExemplo.first));

  setUp(() {
    tarefas = MockTarefaRepository();
    // A revisão vinculada ao exemplo C.
    when(() => tarefas.getAll()).thenAnswer(
      (_) async => [
        tarefasExemplo.first.copyWith(orcamentoId: 'orcamento-c'),
        ...tarefasExemplo.skip(1),
      ],
    );
    when(() => tarefas.save(any())).thenAnswer((_) async {});
    when(() => tarefas.delete(any())).thenAnswer((_) async {});
    orcamentos = MockOrcamentoRepository();
    when(orcamentos.listarResumos).thenAnswer((_) async => orcamentosExemplo);
  });

  /// Abre o formulário por cima de uma tela "cronograma" de mentira, para
  /// conferir que salvar e excluir voltam para ela. "Agora" é 09/10/2023
  /// 08:00.
  Future<void> abrirFormulario(
    WidgetTester tester, {
    String? id,
    String? orcamentoId,
    ThemeMode themeMode = ThemeMode.light,
    bool assentar = true,
  }) async {
    tester.view
      ..physicalSize = const Size(360, 1600)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: AppRoutes.agenda,
      routes: [
        GoRoute(
          path: AppRoutes.agenda,
          builder: (_, _) => const Text('cronograma'),
          routes: [
            GoRoute(
              path: 'tarefa',
              builder: (_, state) => TarefaFormPage(
                tarefaId: state.uri.queryParameters['id'],
                orcamentoId: state.uri.queryParameters['orcamentoId'],
              ),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tarefaRepositoryProvider.overrideWithValue(tarefas),
          orcamentoRepositoryProvider.overrideWithValue(orcamentos),
          agoraProvider.overrideWithValue(DateTime(2023, 10, 9, 8)),
        ],
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
    unawaited(router.push(AppRoutes.tarefa(id: id, orcamentoId: orcamentoId)));
    // Com um indicador de carregamento na tela, nada assenta.
    if (assentar) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    }
  }

  Finder campo(String nome) => find.byKey(ValueKey('tarefa-$nome'));

  Future<void> escolherNoDropdown(
    WidgetTester tester,
    String campoNome,
    String opcao,
  ) async {
    await tester.tap(campo(campoNome));
    await tester.pumpAndSettle();
    await tester.tap(find.text(opcao).last);
    await tester.pumpAndSettle();
  }

  for (final modo in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('nova tarefa começa vazia (${modo.name})', (tester) async {
      await abrirFormulario(tester, themeMode: modo);

      expect(find.text('Nova tarefa'), findsOneWidget);
      expect(find.text('Excluir tarefa'), findsNothing);
      for (final nome in ['titulo', 'data', 'hora', 'descricao']) {
        expect(
          tester.widget<TextFormField>(campo(nome)).controller!.text,
          isEmpty,
        );
      }
      expect(find.text('Nenhum'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('valida os campos obrigatórios', (tester) async {
    await abrirFormulario(tester);

    await tester.tap(find.text('Salvar tarefa'));
    await tester.pumpAndSettle();

    // Título, data, hora e tipo.
    expect(find.text('Campo obrigatório'), findsNWidgets(4));
    verifyNever(() => tarefas.save(any()));
    expect(find.byType(TarefaFormPage), findsOneWidget);
  });

  testWidgets('cria a tarefa e volta para o cronograma', (tester) async {
    await abrirFormulario(tester);

    await tester.enterText(campo('titulo'), '  Visita técnica na obra ');
    await tester.tap(campo('data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('12'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('12/10/2023'), findsOneWidget);

    await tester.tap(campo('hora'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('08:00'), findsOneWidget);

    await escolherNoDropdown(tester, 'tipo', 'Visita');
    await tester.enterText(campo('descricao'), 'Medir o vão do portão');
    await escolherNoDropdown(
      tester,
      'orcamento',
      '051023-02 rev. 2 - Metalúrgica ABC Ltda',
    );

    await tester.tap(find.text('Salvar tarefa'));
    await tester.pumpAndSettle();

    final salva =
        verify(() => tarefas.save(captureAny())).captured.single as Tarefa;
    expect(salva.id, isNotEmpty);
    expect(salva.titulo, 'Visita técnica na obra');
    expect(salva.data, DateTime(2023, 10, 12, 8));
    expect(salva.tipo, TipoTarefa.visita);
    expect(salva.concluida, isFalse);
    expect(salva.descricao, 'Medir o vão do portão');
    expect(salva.orcamentoId, 'orcamento-e');
    expect(find.text('cronograma'), findsOneWidget);
  });

  testWidgets('edição carrega a tarefa e preserva id e conclusão', (
    tester,
  ) async {
    await abrirFormulario(tester, id: 'tarefa-manutencao-torno');

    expect(find.text('Editar tarefa'), findsOneWidget);
    expect(find.text('Manutenção preventiva Torno CNC'), findsOneWidget);
    expect(find.text('09/10/2023'), findsOneWidget);
    expect(find.text('11:30'), findsOneWidget);
    expect(find.text('Produção'), findsOneWidget);

    await tester.enterText(campo('titulo'), 'Manutenção do torno');
    await tester.tap(find.text('Salvar tarefa'));
    await tester.pumpAndSettle();

    final salva =
        verify(() => tarefas.save(captureAny())).captured.single as Tarefa;
    expect(
      (salva.id, salva.titulo, salva.concluida, salva.data),
      (
        'tarefa-manutencao-torno',
        'Manutenção do torno',
        true,
        DateTime(2023, 10, 9, 11, 30),
      ),
    );
  });

  testWidgets('edição mostra o orçamento vinculado', (tester) async {
    await abrirFormulario(tester, id: 'tarefa-revisar-orcamento');

    expect(find.text('071023-01 - João da Silva'), findsOneWidget);
  });

  testWidgets('excluir pede confirmação', (tester) async {
    await abrirFormulario(tester, id: 'tarefa-revisar-orcamento');

    await tester.tap(find.text('Excluir tarefa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    verifyNever(() => tarefas.delete(any()));

    await tester.tap(find.text('Excluir tarefa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();

    verify(() => tarefas.delete('tarefa-revisar-orcamento')).called(1);
    expect(find.text('cronograma'), findsOneWidget);
  });

  testWidgets('tarefa inexistente mostra "não encontrada"', (tester) async {
    await abrirFormulario(tester, id: 'nao-existe');

    expect(find.text('Tarefa não encontrada.'), findsOneWidget);
  });

  group('"Agendar" a partir do orçamento', () {
    String titulo(WidgetTester tester) =>
        tester.widget<TextFormField>(campo('titulo')).controller!.text;

    for (final modo in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('preenche vínculo, tipo e título (${modo.name})', (
        tester,
      ) async {
        // O exemplo E está na 2ª revisão: o título usa o código sem ela.
        await abrirFormulario(
          tester,
          orcamentoId: 'orcamento-e',
          themeMode: modo,
        );

        expect(find.text('Nova tarefa'), findsOneWidget);
        expect(titulo(tester), 'Produção 051023-02');
        expect(find.text('Produção'), findsOneWidget);
        expect(
          find.text('051023-02 rev. 2 - Metalúrgica ABC Ltda'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('salva a tarefa vinculada com o título', (tester) async {
      await abrirFormulario(tester, orcamentoId: 'orcamento-e');

      await tester.tap(campo('data'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(campo('hora'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salvar tarefa'));
      await tester.pumpAndSettle();

      final salva =
          verify(() => tarefas.save(captureAny())).captured.single as Tarefa;
      expect(
        (salva.titulo, salva.tipo, salva.orcamentoId),
        ('Produção 051023-02', TipoTarefa.producao, 'orcamento-e'),
      );
    });

    testWidgets('o título acompanha o tipo até ser editado', (tester) async {
      await abrirFormulario(tester, orcamentoId: 'orcamento-e');

      await escolherNoDropdown(tester, 'tipo', 'Visita');
      expect(titulo(tester), 'Visita 051023-02');

      await tester.enterText(campo('titulo'), 'Medir o vão');
      await escolherNoDropdown(tester, 'tipo', 'Orçamento');
      expect(titulo(tester), 'Medir o vão');
    });

    testWidgets('orçamento inexistente mantém o vínculo, sem título', (
      tester,
    ) async {
      await abrirFormulario(tester, orcamentoId: 'excluido');

      expect(titulo(tester), isEmpty);
      expect(find.text('Produção'), findsOneWidget);
      expect(find.text('Orçamento não encontrado'), findsOneWidget);
    });

    testWidgets('espera o orçamento carregar', (tester) async {
      final carregando = Completer<List<Orcamento>>();
      when(orcamentos.listarResumos).thenAnswer((_) => carregando.future);
      await abrirFormulario(
        tester,
        orcamentoId: 'orcamento-e',
        assentar: false,
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);

      carregando.complete(orcamentosExemplo);
      await tester.pumpAndSettle();
      expect(titulo(tester), 'Produção 051023-02');
    });
  });

  // Tarefa sem vínculo (ou cujo orçamento foi excluído): o formulário abre
  // sem esperar orçamento nenhum.
  for (final id in [null, 'tarefa-manutencao-torno']) {
    testWidgets('sem vínculo não espera orçamento (${id ?? 'nova'})', (
      tester,
    ) async {
      when(
        orcamentos.listarResumos,
      ).thenAnswer((_) => Completer<List<Orcamento>>().future);
      await abrirFormulario(tester, id: id);

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Salvar tarefa'), findsOneWidget);
    });
  }
}
