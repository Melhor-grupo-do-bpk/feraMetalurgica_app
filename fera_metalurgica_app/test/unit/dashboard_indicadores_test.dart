import 'package:fera_metalurgica_app/features/cronograma/cronograma.dart';
import 'package:fera_metalurgica_app/features/dashboard/presentation/dashboard_indicadores.dart';
import 'package:fera_metalurgica_app/features/orcamentos/orcamentos.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../mocks/mock_cronograma_repository.dart';
import '../mocks/mock_orcamento_repository.dart';

/// Um orçamento do seed com [status] e [id] trocados.
Orcamento _orcamento(String id, StatusOrcamento status, DateTime criadoEm) =>
    orcamentosSeed.first.copyWith(id: id, status: status, criadoEm: criadoEm);

/// Uma tarefa do seed com [tipo] e [concluida] trocados.
Tarefa _tarefa(TipoTarefa tipo, {bool concluida = false}) =>
    cronogramaSeed.first.copyWith(tipo: tipo, concluida: concluida);

void main() {
  group('calcularIndicadores (D-03)', () {
    test('conta cada status no seu card', () {
      final indicadores = calcularIndicadores([
        _orcamento('1', StatusOrcamento.emAnalise, DateTime(2026)),
        _orcamento('2', StatusOrcamento.emAnalise, DateTime(2026)),
        _orcamento('3', StatusOrcamento.enviado, DateTime(2026)),
        _orcamento('4', StatusOrcamento.aprovado, DateTime(2026)),
        _orcamento('5', StatusOrcamento.aprovado, DateTime(2026)),
        _orcamento('6', StatusOrcamento.aprovado, DateTime(2026)),
      ], const []);

      expect(indicadores.emAndamento, 2);
      expect(indicadores.aguardandoAprovacao, 1);
      expect(indicadores.aprovados, 3);
      expect(indicadores.pedidosEmProducao, 0);
    });

    test('rascunho e recusado não contam em nenhum card', () {
      final indicadores = calcularIndicadores([
        _orcamento('1', StatusOrcamento.rascunho, DateTime(2026)),
        _orcamento('2', StatusOrcamento.recusado, DateTime(2026)),
      ], const []);

      expect(indicadores, (
        emAndamento: 0,
        aguardandoAprovacao: 0,
        aprovados: 0,
        pedidosEmProducao: 0,
      ));
    });

    test('só tarefas de produção não concluídas contam', () {
      final indicadores = calcularIndicadores(const [], [
        _tarefa(TipoTarefa.producao),
        _tarefa(TipoTarefa.producao),
        _tarefa(TipoTarefa.producao, concluida: true),
        _tarefa(TipoTarefa.orcamento),
        _tarefa(TipoTarefa.visita),
      ]);

      expect(indicadores.pedidosEmProducao, 2);
    });

    test('com os dados de exemplo', () {
      expect(calcularIndicadores(orcamentosSeed, cronogramaSeed), (
        emAndamento: 1,
        aguardandoAprovacao: 1,
        aprovados: 1,
        pedidosEmProducao: 1,
      ));
    });
  });

  group('selecionarRecentes (RF-12)', () {
    test('pula rascunhos, mantém a ordem e limita a 2', () {
      final recentes = selecionarRecentes([
        _orcamento('5', StatusOrcamento.rascunho, DateTime(2026, 5)),
        _orcamento('4', StatusOrcamento.aprovado, DateTime(2026, 4)),
        _orcamento('3', StatusOrcamento.rascunho, DateTime(2026, 3)),
        _orcamento('2', StatusOrcamento.emAnalise, DateTime(2026, 2)),
        _orcamento('1', StatusOrcamento.enviado, DateTime(2026)),
      ]);

      expect(recentes.map((o) => o.id), ['4', '2']);
    });

    test('recusado aparece nos recentes, mas não conta nos cards', () {
      final orcamentos = [
        _orcamento('2', StatusOrcamento.recusado, DateTime(2026, 2)),
        _orcamento('1', StatusOrcamento.rascunho, DateTime(2026)),
      ];

      expect(selecionarRecentes(orcamentos).map((o) => o.id), ['2']);
      final indicadores = calcularIndicadores(orcamentos, const []);
      expect(
        indicadores.emAndamento +
            indicadores.aguardandoAprovacao +
            indicadores.aprovados,
        0,
      );
    });

    test('lista vazia ou só de rascunhos dá nenhum recente', () {
      expect(selecionarRecentes(const []), isEmpty);
      expect(
        selecionarRecentes([
          _orcamento('1', StatusOrcamento.rascunho, DateTime(2026)),
        ]),
        isEmpty,
      );
    });
  });

  test('formatarContagem usa pelo menos 2 dígitos', () {
    expect(formatarContagem(0), '00');
    expect(formatarContagem(8), '08');
    expect(formatarContagem(45), '45');
    expect(formatarContagem(123), '123');
  });

  group('providers', () {
    late MockOrcamentoRepository orcamentos;
    late MockCronogramaRepository tarefas;
    late ProviderContainer container;

    setUpAll(() => registerFallbackValue(cronogramaSeed.first));

    setUp(() {
      orcamentos = MockOrcamentoRepository();
      tarefas = MockCronogramaRepository();
      when(() => orcamentos.getAll()).thenAnswer((_) async => orcamentosSeed);
      when(() => tarefas.getAll()).thenAnswer((_) async => cronogramaSeed);
      container = ProviderContainer(
        // Sem o retry automático do Riverpod, para o erro aparecer na hora.
        retry: (_, _) => null,
        overrides: [
          orcamentoRepositoryProvider.overrideWithValue(orcamentos),
          cronogramaRepositoryProvider.overrideWithValue(tarefas),
        ],
      );
      addTearDown(container.dispose);
      container
        ..listen(indicadoresDashboardProvider, (_, _) {})
        ..listen(recentesDashboardProvider, (_, _) {});
    });

    Future<void> carregar() async {
      await container.read(orcamentosProvider.future);
      await container.read(tarefasProvider.future);
    }

    test('combinam orçamentos e tarefas', () async {
      await carregar();

      expect(container.read(indicadoresDashboardProvider).value, (
        emAndamento: 1,
        aguardandoAprovacao: 1,
        aprovados: 1,
        pedidosEmProducao: 1,
      ));
      expect(
        container.read(recentesDashboardProvider).value?.map((o) => o.id),
        ['00482', '00481'],
      );
    });

    test('salvar um orçamento atualiza indicadores e recentes', () async {
      await carregar();
      final novo = _orcamento(
        '00483',
        StatusOrcamento.emAnalise,
        DateTime(2026, 9),
      );
      when(() => orcamentos.save(novo)).thenAnswer((_) async {});
      when(
        () => orcamentos.getAll(),
      ).thenAnswer((_) async => [...orcamentosSeed, novo]);

      await container.read(orcamentosProvider.notifier).salvar(novo);

      expect(
        container.read(indicadoresDashboardProvider).value?.emAndamento,
        2,
      );
      expect(
        container.read(recentesDashboardProvider).value?.map((o) => o.id),
        ['00483', '00482'],
      );
    });

    test('concluir uma tarefa de produção atualiza o card', () async {
      await carregar();
      when(() => tarefas.save(any())).thenAnswer((_) async {});
      when(() => tarefas.getAll()).thenAnswer(
        (_) async => [
          for (final t in cronogramaSeed) t.copyWith(concluida: true),
        ],
      );

      await container
          .read(tarefasProvider.notifier)
          .alternarConcluida('tarefa-producao-00124');

      expect(
        container.read(indicadoresDashboardProvider).value?.pedidosEmProducao,
        0,
      );
    });

    test('erro em qualquer um dos dois vira erro nos indicadores', () async {
      when(() => tarefas.getAll()).thenThrow(Exception('falhou'));
      container.invalidate(tarefasProvider);
      await container.read(orcamentosProvider.future);
      await expectLater(
        container.read(tarefasProvider.future),
        throwsException,
      );

      expect(container.read(indicadoresDashboardProvider).hasError, isTrue);
      expect(container.read(recentesDashboardProvider).hasValue, isTrue);
    });
  });
}
