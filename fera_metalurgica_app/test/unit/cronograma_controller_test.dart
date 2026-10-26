import 'package:fera_metalurgica_app/features/cronograma/cronograma.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../mocks/fake_local_json_storage.dart';

void main() {
  late ProviderContainer container;
  late LocalCronogramaRepository repository;

  setUp(() async {
    repository = LocalCronogramaRepository(InMemoryJsonStorage());
    for (final tarefa in cronogramaSeed.reversed) {
      await repository.save(tarefa);
    }
    container = ProviderContainer(
      overrides: [cronogramaRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  test('carrega em ordem cronológica', () async {
    expect(await container.read(tarefasProvider.future), cronogramaSeed);
  });

  test('salvar e excluir atualizam o estado e o repositório', () async {
    await container.read(tarefasProvider.future);
    final nova = Tarefa(
      id: 'nova',
      titulo: 'Visita técnica',
      data: DateTime(2023, 10, 9, 8),
      tipo: TipoTarefa.visita,
    );
    final notifier = container.read(tarefasProvider.notifier);

    await notifier.salvar(nova);
    expect(container.read(tarefasProvider).value!.first, nova);
    expect(await container.read(tarefaPorIdProvider('nova').future), nova);

    await notifier.excluir('nova');
    expect(container.read(tarefasProvider).value, cronogramaSeed);
    expect(await repository.getAll(), isNot(contains(nova)));
  });

  test('alternarConcluida inverte o estado da tarefa', () async {
    await container.read(tarefasProvider.future);
    final id = cronogramaSeed.first.id;
    final notifier = container.read(tarefasProvider.notifier);
    Future<bool> concluidaSalva() async =>
        (await repository.getAll()).firstWhere((t) => t.id == id).concluida;

    await notifier.alternarConcluida(id);
    expect(await concluidaSalva(), isTrue);
    expect(container.read(tarefasProvider).value!.first.concluida, isTrue);

    await notifier.alternarConcluida(id);
    expect(await concluidaSalva(), isFalse);
  });

  test('alternarConcluida ignora id inexistente', () async {
    await container.read(tarefasProvider.future);

    await container.read(tarefasProvider.notifier).alternarConcluida('x');

    expect(container.read(tarefasProvider).value, cronogramaSeed);
  });
}
