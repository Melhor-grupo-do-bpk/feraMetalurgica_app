import 'package:fera_metalurgica_app/core/di/banco_de_dados.dart';
import 'package:fera_metalurgica_app/core/di/relogio_provider.dart';
import 'package:fera_metalurgica_app/features/orcamentos/orcamentos.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../mocks/banco_de_teste.dart';
import '../mocks/dados_exemplo.dart';

void main() {
  final agora = DateTime(2023, 10, 9, 14, 30);
  late ProviderContainer container;
  late SqliteOrcamentoRepository repository;

  setUp(() async {
    final banco = await bancoDeTeste();
    addTearDown(banco.close);
    repository = SqliteOrcamentoRepository(banco);
    await repository.inserir(orcamentoExemploC);
    await repository.inserir(orcamentoExemploB);
    container = ProviderContainer(
      overrides: [
        bancoDeDadosProvider.overrideWithValue(banco),
        agoraProvider.overrideWithValue(agora),
      ],
    );
    addTearDown(container.dispose);
  });

  Orcamentos notifier() => container.read(orcamentosProvider.notifier);

  test('carrega do atualizadoEm mais recente ao mais antigo', () async {
    final orcamentos = await container.read(orcamentosProvider.future);

    expect(orcamentos, [orcamentoExemploB, orcamentoExemploC]);
    expect(
      await container.read(orcamentoPorIdProvider('orcamento-c').future),
      orcamentoExemploC,
    );
  });

  test('excluir remove do banco e do estado', () async {
    await container.read(orcamentosProvider.future);

    await notifier().excluir('orcamento-c');

    expect(container.read(orcamentosProvider).value, [orcamentoExemploB]);
    expect(await repository.buscarPorId('orcamento-c'), isNull);
    expect(
      await container.read(orcamentoPorIdProvider('orcamento-c').future),
      isNull,
    );
  });

  group('alterarStatus (D-29, D-37)', () {
    test(
      'enviar grava enviadoEm e não mexe em atualizadoEm nem revisão',
      () async {
        await container.read(orcamentosProvider.future);

        await notifier().alterarStatus('orcamento-c', StatusOrcamento.enviado);

        final salvo = (await repository.buscarPorId('orcamento-c'))!;
        expect(salvo.status, StatusOrcamento.enviado);
        expect(salvo.enviadoEm, agora);
        expect(salvo.atualizadoEm, orcamentoExemploC.atualizadoEm);
        expect(salvo.revisao, 1);
        expect(salvo.dataValidade, orcamentoExemploC.dataValidade);
        expect(container.read(orcamentosProvider).value!.last, salvo);
      },
    );

    test('voltar para criado limpa o enviadoEm', () async {
      await notifier().alterarStatus('orcamento-c', StatusOrcamento.enviado);
      await notifier().alterarStatus('orcamento-c', StatusOrcamento.criado);

      final salvo = (await repository.buscarPorId('orcamento-c'))!;
      expect(salvo.status, StatusOrcamento.criado);
      expect(salvo.enviadoEm, isNull);
    });

    test('reenviar não muda a data do primeiro envio', () async {
      await notifier().alterarStatus('orcamento-c', StatusOrcamento.enviado);
      container.updateOverrides([
        bancoDeDadosProvider.overrideWithValue(
          container.read(bancoDeDadosProvider),
        ),
        agoraProvider.overrideWithValue(agora.add(const Duration(days: 1))),
      ]);

      await notifier().alterarStatus('orcamento-c', StatusOrcamento.enviado);

      expect((await repository.buscarPorId('orcamento-c'))!.enviadoEm, agora);
    });

    test('orçamento inexistente não faz nada', () async {
      await notifier().alterarStatus('nao-existe', StatusOrcamento.enviado);
      expect(await repository.listarResumos(), hasLength(2));
    });
  });
}
