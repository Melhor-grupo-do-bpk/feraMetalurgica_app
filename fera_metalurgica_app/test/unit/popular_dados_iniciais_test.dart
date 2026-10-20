import 'package:fera_metalurgica_app/features/catalogo/catalogo.dart';
import 'package:fera_metalurgica_app/features/cronograma/cronograma.dart';
import 'package:fera_metalurgica_app/features/orcamentos/orcamentos.dart';
import 'package:fera_metalurgica_app/main.dart';
import 'package:flutter_test/flutter_test.dart';

import '../mocks/fake_local_json_storage.dart';

void main() {
  late InMemoryJsonStorage storage;

  setUp(() => storage = InMemoryJsonStorage());

  test('com exemplos, grava catálogo, orçamentos e tarefas', () async {
    await popularDadosIniciais(storage, incluirExemplos: true);

    expect(await LocalCatalogoRepository(storage).getAll(), catalogoSeed);
    expect(await LocalOrcamentoRepository(storage).getAll(), orcamentosSeed);
    expect(await LocalCronogramaRepository(storage).getAll(), cronogramaSeed);
  });

  test('sem exemplos (release), grava só o catálogo', () async {
    await popularDadosIniciais(storage, incluirExemplos: false);

    expect(await LocalCatalogoRepository(storage).getAll(), catalogoSeed);
    expect(await LocalOrcamentoRepository(storage).getAll(), isEmpty);
    expect(await LocalCronogramaRepository(storage).getAll(), isEmpty);
  });

  test('não semeia de novo um arquivo que já existe, mesmo vazio', () async {
    await popularDadosIniciais(storage, incluirExemplos: true);
    final repository = LocalOrcamentoRepository(storage);
    for (final orcamento in orcamentosSeed) {
      await repository.delete(orcamento.id);
    }

    await popularDadosIniciais(storage, incluirExemplos: true);

    expect(await repository.getAll(), isEmpty);
  });
}
