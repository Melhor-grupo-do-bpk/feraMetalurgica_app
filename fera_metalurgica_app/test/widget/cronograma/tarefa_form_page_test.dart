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

import '../../mocks/mock_cronograma_repository.dart';
import '../../mocks/mock_orcamento_repository.dart';

void main() {
  late MockCronogramaRepository tarefas;
  late MockOrcamentoRepository orcamentos;

  setUpAll(() => registerFallbackValue(cronogramaSeed.first));

  setUp(() {
    tarefas = MockCronogramaRepository();
    when(() => tarefas.getAll()).thenAnswer((_) async => cronogramaSeed);
    when(() => tarefas.save(any())).thenAnswer((_) async {});
    when(() => tarefas.delete(any())).thenAnswer((_) async {});
    orcamentos = MockOrcamentoRepository();
    when(() => orcamentos.getAll()).thenAnswer((_) async => orcamentosSeed);
  });

  /// Abre o formulário por cima de uma tela "cronograma" de mentira, para
  /// conferir que salvar e excluir voltam para ela. "Agora" é 09/10/2023
  /// 08:00.
  Future<void> abrirFormulario(
    WidgetTester tester, {
    String? id,
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    tester.view
      ..physicalSize = const Size(360, 1600)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: AppRoutes.cronograma,
      routes: [
        GoRoute(
          path: AppRoutes.cronograma,
          builder: (_, _) => const Text('cronograma'),
          routes: [
            GoRoute(
              path: 'tarefa',
              builder: (_, state) =>
                  TarefaFormPage(tarefaId: state.uri.queryParameters['id']),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cronogramaRepositoryProvider.overrideWithValue(tarefas),
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
    unawaited(router.push(AppRoutes.tarefa(id: id)));
    await tester.pumpAndSettle();
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
      '#00481 - Metalúrgica ABC Ltda',
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
    expect(salva.orcamentoId, '00481');
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
    await abrirFormulario(tester, id: 'tarefa-revisar-00482');

    expect(find.text('#00482 - João da Silva'), findsOneWidget);
  });

  testWidgets('excluir pede confirmação', (tester) async {
    await abrirFormulario(tester, id: 'tarefa-revisar-00482');

    await tester.tap(find.text('Excluir tarefa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    verifyNever(() => tarefas.delete(any()));

    await tester.tap(find.text('Excluir tarefa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();

    verify(() => tarefas.delete('tarefa-revisar-00482')).called(1);
    expect(find.text('cronograma'), findsOneWidget);
  });

  testWidgets('tarefa inexistente mostra "não encontrada"', (tester) async {
    await abrirFormulario(tester, id: 'nao-existe');

    expect(find.text('Tarefa não encontrada.'), findsOneWidget);
  });
}
