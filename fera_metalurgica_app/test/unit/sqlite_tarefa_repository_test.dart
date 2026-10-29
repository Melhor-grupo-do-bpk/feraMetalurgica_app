import 'package:fera_metalurgica_app/features/cronograma/cronograma.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../mocks/banco_de_teste.dart';
import '../mocks/dados_exemplo.dart';

void main() {
  late Database banco;
  late SqliteTarefaRepository repository;

  setUp(() async {
    banco = await bancoDeTeste();
    repository = SqliteTarefaRepository(banco);
  });
  tearDown(() => banco.close());

  test('getAll devolve lista vazia quando nada foi salvo', () async {
    expect(await repository.getAll(), isEmpty);
  });

  test('save persiste e getAll lê de volta, em ordem de data', () async {
    for (final tarefa in tarefasExemplo.reversed) {
      await repository.save(tarefa);
    }

    expect(await repository.getAll(), tarefasExemplo);
  });

  test('a data volta com hora, minuto e microssegundos', () async {
    final tarefa = tarefasExemplo.first.copyWith(
      data: DateTime(2026, 10, 29, 14, 35, 12, 345, 678),
    );
    await repository.save(tarefa);
    expect((await repository.getAll()).single.data, tarefa.data);
  });

  test('save com id existente substitui a tarefa', () async {
    final original = tarefasExemplo.first;
    await repository.save(original);
    await repository.save(original.copyWith(concluida: true));

    final todas = await repository.getAll();
    expect(todas, hasLength(1));
    expect(todas.single.concluida, isTrue);
  });

  test('delete remove apenas a tarefa do id informado', () async {
    for (final tarefa in tarefasExemplo) {
      await repository.save(tarefa);
    }

    await repository.delete(tarefasExemplo.first.id);

    expect(await repository.getAll(), tarefasExemplo.skip(1).toList());
  });
}
