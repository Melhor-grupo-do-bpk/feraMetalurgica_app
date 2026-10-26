import 'package:fera_metalurgica_app/features/orcamentos/orcamentos.dart';
import 'package:flutter_test/flutter_test.dart';

import '../mocks/fake_local_json_storage.dart';

void main() {
  late LocalOrcamentoRepository repository;

  setUp(() {
    repository = LocalOrcamentoRepository(InMemoryJsonStorage());
  });

  test('getAll devolve lista vazia quando nada foi salvo', () async {
    expect(await repository.getAll(), isEmpty);
  });

  test('save persiste e getAll lê de volta (ida e volta JSON)', () async {
    for (final orcamento in orcamentosSeed) {
      await repository.save(orcamento);
    }

    expect(await repository.getAll(), orcamentosSeed);
  });

  test('save com id existente substitui o orçamento', () async {
    final original = orcamentosSeed.first;
    await repository.save(original);
    await repository.save(original.copyWith(status: StatusOrcamento.enviado));

    final todos = await repository.getAll();
    expect(todos, hasLength(1));
    expect(todos.single.status, StatusOrcamento.enviado);
  });

  test('delete remove apenas o orçamento do id informado', () async {
    for (final orcamento in orcamentosSeed) {
      await repository.save(orcamento);
    }

    await repository.delete('00482');

    final ids = (await repository.getAll()).map((o) => o.id);
    expect(ids, orcamentosSeed.skip(1).map((o) => o.id));
  });
}
