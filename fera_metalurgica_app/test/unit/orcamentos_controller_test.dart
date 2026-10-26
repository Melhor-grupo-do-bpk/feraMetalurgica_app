import 'package:fera_metalurgica_app/features/orcamentos/orcamentos.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../mocks/fake_local_json_storage.dart';

void main() {
  late ProviderContainer container;
  late LocalOrcamentoRepository repository;

  setUp(() async {
    repository = LocalOrcamentoRepository(InMemoryJsonStorage());
    // Fora de ordem de propósito, para testar a ordenação.
    for (final orcamento in orcamentosSeed.reversed) {
      await repository.save(orcamento);
    }
    container = ProviderContainer(
      overrides: [orcamentoRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  test('carrega do mais recente ao mais antigo', () async {
    final orcamentos = await container.read(orcamentosProvider.future);

    expect(orcamentos.map((o) => o.id), [
      '00482',
      '00481',
      '00480',
      '00479',
      '00478',
    ]);
  });

  test('salvar grava no repositório e atualiza quem está ouvindo', () async {
    await container.read(orcamentosProvider.future);
    final novo = orcamentosSeed.first.copyWith(
      id: '00483',
      criadoEm: DateTime(2026, 9),
    );

    await container.read(orcamentosProvider.notifier).salvar(novo);

    expect(container.read(orcamentosProvider).value!.first, novo);
    expect(await repository.getAll(), contains(novo));
    expect(
      await container.read(orcamentoPorIdProvider('00483').future),
      novo,
    );
  });

  test('excluir remove do repositório e do estado', () async {
    await container.read(orcamentosProvider.future);

    await container.read(orcamentosProvider.notifier).excluir('00482');

    expect(
      container.read(orcamentosProvider).value!.map((o) => o.id),
      isNot(contains('00482')),
    );
    expect(
      await container.read(orcamentoPorIdProvider('00482').future),
      isNull,
    );
  });
}
