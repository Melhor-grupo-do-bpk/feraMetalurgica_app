import 'package:fera_metalurgica_app/core/di/banco_de_dados.dart';
import 'package:fera_metalurgica_app/core/di/local_storage_provider.dart';
import 'package:fera_metalurgica_app/core/di/relogio_provider.dart';
import 'package:fera_metalurgica_app/core/domain/dinheiro.dart';
import 'package:fera_metalurgica_app/features/catalogo/catalogo.dart';
import 'package:fera_metalurgica_app/features/clientes/clientes.dart';
import 'package:fera_metalurgica_app/features/cronograma/cronograma.dart';
import 'package:fera_metalurgica_app/features/empresa/empresa.dart';
import 'package:fera_metalurgica_app/features/materiais/materiais.dart';
import 'package:fera_metalurgica_app/features/orcamentos/orcamentos.dart';
import 'package:fera_metalurgica_app/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../mocks/banco_de_teste.dart';
import '../mocks/fake_local_json_storage.dart';

void main() {
  final agora = DateTime(2026, 10, 29, 16, 45);
  late InMemoryJsonStorage storage;
  late ProviderContainer container;

  setUp(() async {
    storage = InMemoryJsonStorage();
    final banco = await bancoDeTeste();
    container = ProviderContainer(
      overrides: [
        bancoDeDadosProvider.overrideWithValue(banco),
        localJsonStorageProvider.overrideWithValue(storage),
        agoraProvider.overrideWithValue(agora),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await banco.close();
    });
  });

  Future<void> popular({bool bancoNovo = true, bool exemplos = true}) =>
      popularDadosIniciais(
        container,
        bancoNovo: bancoNovo,
        incluirExemplos: exemplos,
      );

  Future<List<Orcamento>> orcamentos() =>
      container.read(orcamentoRepositoryProvider).listarResumos();

  group('com exemplos (debug, D-17)', () {
    setUp(popular);

    test('grava a empresa completa e um material de cada unidade', () async {
      final empresa = await container.read(empresaRepositoryProvider).obter();
      expect(empresa, empresaExemplo);
      expect(empresa!.estaCompleta, isTrue);
      expect(
        await container.read(materialRepositoryProvider).listarTodos(),
        unorderedEquals(materiaisExemplo),
      );
      expect(
        materiaisExemplo.map((m) => m.unidade).toSet(),
        UnidadeCobranca.values.toSet(),
      );
    });

    test(r'grava os orçamentos C (R$ 3.630,80) e B (R$ 644,40)', () async {
      final [b, c] = await orcamentos();

      expect(c.totalGeral, Dinheiro.parse('3.630,80'));
      expect(c.cliente.nome, 'João da Silva');
      expect(b.totalGeral, Dinheiro.parse('644,40'));
      expect(b.cliente.nome, 'Construtora Horizonte Ltda');
      for (final o in [b, c]) {
        expect(o.status, StatusOrcamento.criado);
        expect(o.revisao, 1);
      }
    });

    test(
      'os orçamentos são de dias anteriores: o de hoje começa em -01',
      () async {
        final [b, c] = await orcamentos();

        expect(c.codigo, '271026-01');
        expect(c.criadoEm, DateTime(2026, 10, 27, 10));
        expect(b.codigo, '281026-01');
        expect(b.criadoEm, DateTime(2026, 10, 28, 15));
        final hoje = await container
            .read(unidadeDeTrabalhoProvider)
            .executarEmTransacao(
              (repos) => repos.sequencias.proximaDoDia(agora),
            );
        expect(hoje, 1);
      },
    );

    test('os clientes dos exemplos ficam cadastrados', () async {
      expect(
        (await container.read(clienteRepositoryProvider).pesquisar('')).map(
          (c) => c.nome,
        ),
        ['Construtora Horizonte Ltda', 'João da Silva'],
      );
    });

    test(
      'as tarefas são de hoje e de amanhã, ligadas ao orçamento C',
      () async {
        final tarefas = await container.read(tarefaRepositoryProvider).getAll();
        final c = (await orcamentos()).last;

        expect(
          tarefas.map((t) => DateTime(t.data.year, t.data.month, t.data.day)),
          [
            DateTime(2026, 10, 29),
            DateTime(2026, 10, 29),
            DateTime(2026, 10, 30),
          ],
        );
        final revisao = tarefas.first;
        expect(revisao.orcamentoId, c.id);
        expect(revisao.titulo, 'Revisar orçamento 271026-01');
      },
    );

    test('o catálogo continua semeado', () async {
      expect(await LocalCatalogoRepository(storage).getAll(), catalogoSeed);
    });
  });

  test('sem exemplos (release), o banco fica vazio', () async {
    await popular(exemplos: false);

    expect(await container.read(empresaRepositoryProvider).obter(), isNull);
    expect(await orcamentos(), isEmpty);
    expect(await container.read(tarefaRepositoryProvider).getAll(), isEmpty);
    expect(await LocalCatalogoRepository(storage).getAll(), catalogoSeed);
  });

  test('banco que já existia não recebe os exemplos de novo', () async {
    await popular(bancoNovo: false);

    expect(await container.read(empresaRepositoryProvider).obter(), isNull);
    expect(await orcamentos(), isEmpty);
    expect(await container.read(tarefaRepositoryProvider).getAll(), isEmpty);
  });
}
