import 'package:fera_metalurgica_app/core/di/banco_de_dados.dart';
import 'package:fera_metalurgica_app/core/di/relogio_provider.dart';
import 'package:fera_metalurgica_app/core/domain/dinheiro.dart';
import 'package:fera_metalurgica_app/features/cronograma/cronograma.dart';
import 'package:fera_metalurgica_app/features/dashboard/presentation/dashboard_indicadores.dart';
import 'package:fera_metalurgica_app/features/orcamentos/orcamentos.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../mocks/banco_de_teste.dart';
import '../mocks/dados_exemplo.dart';
import '../mocks/mock_tarefa_repository.dart';

final DateTime _outubro = DateTime(2023, 10, 20, 9);

/// O exemplo B com id e código próprios, `status` e `enviadoEm`.
Orcamento _orcamento(
  String id, {
  StatusOrcamento status = StatusOrcamento.criado,
  DateTime? enviadoEm,
}) => orcamentoExemploB.copyWith(
  id: id,
  codigo: 'cod-$id',
  chaveFinalizacao: 'chave-$id',
  status: status,
  enviadoEm: enviadoEm,
);

/// Uma tarefa de exemplo com [tipo] e [concluida] trocados.
Tarefa _tarefa(TipoTarefa tipo, {bool concluida = false}) =>
    tarefasExemplo.first.copyWith(tipo: tipo, concluida: concluida);

void main() {
  group('calcularIndicadores (D-32)', () {
    test('criados contam pelo status', () {
      final indicadores = calcularIndicadores(
        [
          _orcamento('1'),
          _orcamento('2'),
          _orcamento(
            '3',
            status: StatusOrcamento.enviado,
            enviadoEm: DateTime(2023, 10, 2),
          ),
        ],
        const [],
        _outubro,
      );

      expect(indicadores.criados, 2);
    });

    test('enviados no mês contam por enviadoEm, com o valor somado', () {
      final indicadores = calcularIndicadores(
        [
          _orcamento(
            'outubro-1',
            status: StatusOrcamento.enviado,
            enviadoEm: DateTime(2023, 10),
          ),
          _orcamento(
            'outubro-2',
            status: StatusOrcamento.enviado,
            enviadoEm: DateTime(2023, 10, 31, 23, 59),
          ),
          _orcamento(
            'setembro',
            status: StatusOrcamento.enviado,
            enviadoEm: DateTime(2023, 9, 30, 23, 59),
          ),
          _orcamento(
            'outubro-de-2022',
            status: StatusOrcamento.enviado,
            enviadoEm: DateTime(2022, 10, 15),
          ),
          // Criado em setembro, enviado em outubro: conta em outubro (D-37).
          orcamentoExemploC.copyWith(
            criadoEm: DateTime(2023, 9, 5),
            atualizadoEm: DateTime(2023, 9, 5),
            status: StatusOrcamento.enviado,
            enviadoEm: DateTime(2023, 10, 3),
          ),
        ],
        const [],
        _outubro,
      );

      expect(indicadores.enviadosNoMes, 3);
      expect(indicadores.valorEnviadoNoMes, Dinheiro.parse('4.919,60'));
    });

    test('sem orçamentos, os valores são zero', () {
      expect(calcularIndicadores(const [], const [], _outubro), (
        criados: 0,
        enviadosNoMes: 0,
        valorEnviadoNoMes: Dinheiro.zero,
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
      ], _outubro);

      expect(indicadores.pedidosEmProducao, 2);
    });
  });

  group('selecionarRecentes', () {
    test('os 2 primeiros, na ordem recebida, de qualquer status', () {
      final lista = [
        _orcamento('1', status: StatusOrcamento.enviado),
        _orcamento('2'),
        _orcamento('3'),
      ];
      expect(selecionarRecentes(lista).map((o) => o.id), ['1', '2']);
    });

    test('lista vazia dá nenhum recente', () {
      expect(selecionarRecentes(const []), isEmpty);
    });
  });

  test('formatarContagem usa pelo menos 2 dígitos', () {
    expect(formatarContagem(0), '00');
    expect(formatarContagem(8), '08');
    expect(formatarContagem(45), '45');
    expect(formatarContagem(123), '123');
  });

  group('providers', () {
    late MockTarefaRepository tarefas;
    late ProviderContainer container;

    setUpAll(() => registerFallbackValue(tarefasExemplo.first));

    setUp(() async {
      final banco = await bancoDeTeste();
      addTearDown(banco.close);
      final orcamentos = SqliteOrcamentoRepository(banco);
      await orcamentos.inserir(orcamentoExemploC);
      await orcamentos.inserir(orcamentoExemploB);
      tarefas = MockTarefaRepository();
      when(() => tarefas.getAll()).thenAnswer((_) async => tarefasExemplo);
      container = ProviderContainer(
        // Sem o retry automático do Riverpod, para o erro aparecer na hora.
        retry: (_, _) => null,
        overrides: [
          bancoDeDadosProvider.overrideWithValue(banco),
          tarefaRepositoryProvider.overrideWithValue(tarefas),
          agoraProvider.overrideWithValue(agoraDosExemplos),
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
        criados: 2,
        enviadosNoMes: 0,
        valorEnviadoNoMes: Dinheiro.zero,
        pedidosEmProducao: 1,
      ));
      expect(
        container.read(recentesDashboardProvider).value?.map((o) => o.id),
        ['orcamento-b', 'orcamento-c'],
      );
    });

    test('enviar um orçamento atualiza os cards do mês', () async {
      await carregar();

      await container
          .read(orcamentosProvider.notifier)
          .alterarStatus('orcamento-c', StatusOrcamento.enviado);

      final indicadores = container.read(indicadoresDashboardProvider).value!;
      expect(indicadores.criados, 1);
      expect(indicadores.enviadosNoMes, 1);
      expect(indicadores.valorEnviadoNoMes, Dinheiro.parse('3.630,80'));
    });

    test('concluir uma tarefa de produção atualiza o card', () async {
      await carregar();
      when(() => tarefas.save(any())).thenAnswer((_) async {});
      when(() => tarefas.getAll()).thenAnswer(
        (_) async => [
          for (final t in tarefasExemplo) t.copyWith(concluida: true),
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
