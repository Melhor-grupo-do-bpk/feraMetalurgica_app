import 'package:fera_metalurgica_app/core/di/banco_de_dados.dart';
import 'package:fera_metalurgica_app/core/di/local_storage_provider.dart';
import 'package:fera_metalurgica_app/core/di/relogio_provider.dart';
import 'package:fera_metalurgica_app/features/catalogo/catalogo.dart';
import 'package:fera_metalurgica_app/features/cronograma/cronograma.dart';
import 'package:fera_metalurgica_app/features/orcamentos/orcamentos.dart';
import 'package:fera_metalurgica_app/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../mocks/banco_de_teste.dart';
import '../mocks/dados_exemplo.dart';
import '../mocks/fake_local_json_storage.dart';

void main() {
  late InMemoryJsonStorage storage;
  late ProviderContainer container;

  setUp(() async {
    storage = InMemoryJsonStorage();
    final banco = await bancoDeTeste();
    container = ProviderContainer(
      overrides: [
        bancoDeDadosProvider.overrideWithValue(banco),
        localJsonStorageProvider.overrideWithValue(storage),
        agoraProvider.overrideWithValue(agoraDosExemplos),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await banco.close();
    });
  });

  Future<List<Tarefa>> tarefas() =>
      container.read(tarefaRepositoryProvider).getAll();

  test('com exemplos, grava catálogo, orçamentos e tarefas', () async {
    await popularDadosIniciais(
      container,
      bancoNovo: true,
      incluirExemplos: true,
    );

    expect(await LocalCatalogoRepository(storage).getAll(), catalogoSeed);
    expect(await LocalOrcamentoRepository(storage).getAll(), orcamentosSeed);
    expect(await tarefas(), tarefasExemplo);
  });

  test('as tarefas de exemplo são de hoje e de amanhã (HO-T8-01)', () {
    final dias = cronogramaSeed(
      DateTime(2026, 10, 31, 16),
    ).map((t) => DateTime(t.data.year, t.data.month, t.data.day));
    expect(dias, [
      DateTime(2026, 10, 31),
      DateTime(2026, 10, 31),
      DateTime(2026, 11),
    ]);
  });

  test('sem exemplos (release), grava só o catálogo', () async {
    await popularDadosIniciais(
      container,
      bancoNovo: true,
      incluirExemplos: false,
    );

    expect(await LocalCatalogoRepository(storage).getAll(), catalogoSeed);
    expect(await LocalOrcamentoRepository(storage).getAll(), isEmpty);
    expect(await tarefas(), isEmpty);
  });

  test('banco que já existia não recebe os exemplos de novo', () async {
    await popularDadosIniciais(
      container,
      bancoNovo: false,
      incluirExemplos: true,
    );

    expect(await tarefas(), isEmpty);
  });

  test('não semeia de novo um arquivo que já existe, mesmo vazio', () async {
    await popularDadosIniciais(
      container,
      bancoNovo: true,
      incluirExemplos: true,
    );
    final repository = LocalOrcamentoRepository(storage);
    for (final orcamento in orcamentosSeed) {
      await repository.delete(orcamento.id);
    }

    await popularDadosIniciais(
      container,
      bancoNovo: false,
      incluirExemplos: true,
    );

    expect(await repository.getAll(), isEmpty);
  });
}
