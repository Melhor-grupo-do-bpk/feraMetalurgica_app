import 'package:fera_metalurgica_app/core/domain/dinheiro.dart';
import 'package:fera_metalurgica_app/features/clientes/clientes.dart';
import 'package:fera_metalurgica_app/features/materiais/materiais.dart';
import 'package:fera_metalurgica_app/features/orcamentos/data/sqlite_orcamento_repository.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/v2/material_snapshot.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/v2/orcamento_em_edicao.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/v2/status_orcamento.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../mocks/banco_de_teste.dart';
import 'v2/dados_v2.dart';

Future<int> _contar(Database banco, String tabela) async {
  final linhas = await banco.rawQuery('SELECT COUNT(*) AS n FROM $tabela');
  return linhas.single['n']! as int;
}

var _proximoId = 0;

/// [edicaoB] com itens e peças de ids novos: num banco, cada item e cada
/// peça têm id único, como os UUIDs do app.
OrcamentoEmEdicao _edicaoBNova() => edicaoB.copyWith(
  itens: [
    for (final item in edicaoB.itens)
      item.duplicarComNovosIds(() => 'id-${_proximoId++}'),
  ],
);

void main() {
  late Database banco;
  late SqliteOrcamentoRepository repositorio;
  final orcamentoC = orcamentoSalvo(edicaoC);

  setUp(() async {
    banco = await bancoDeTeste();
    repositorio = SqliteOrcamentoRepository(banco);
  });
  tearDown(() => banco.close());

  test('grava e lê de volta o agregado completo, sem perda', () async {
    await repositorio.inserir(orcamentoC);

    final lido = await repositorio.buscarPorId(orcamentoC.id);
    expect(lido, orcamentoC);
    expect(lido!.totalGeral, Dinheiro.parse('3.630,80'));
    // Ordem dos itens e das peças, material copiado e espessura nula em m².
    expect(lido.itens.map((i) => i.id), ['item-a', 'item-b']);
    expect(lido.itens.first.pecas.map((p) => p.id), ['tampo', 'perna']);
    expect(lido.itens.first.pecas.first.espessuraCm, isNull);
    expect(lido.itens.first.pecas.first.material, granito.gerarSnapshot());
  });

  test('enviadoEm volta igual, inclusive nulo', () async {
    final enviado = orcamentoC.copyWith(
      status: StatusOrcamento.enviado,
      enviadoEm: DateTime(2026, 10, 30, 11, 15, 5, 1, 2),
    );
    await repositorio.inserir(enviado);
    expect(await repositorio.buscarPorId(enviado.id), enviado);

    await repositorio.atualizar(enviado.copyWith(enviadoEm: null));
    expect((await repositorio.buscarPorId(enviado.id))!.enviadoEm, isNull);
  });

  test('busca pela chave de finalização', () async {
    await repositorio.inserir(orcamentoC);
    expect(
      await repositorio.buscarPorChaveFinalizacao(edicaoC.chaveFinalizacao),
      orcamentoC,
    );
    expect(await repositorio.buscarPorChaveFinalizacao('outra'), isNull);
    expect(await repositorio.buscarPorId('outro'), isNull);
  });

  test('listarResumos ordena por atualizadoEm decrescente', () async {
    final antigo = orcamentoSalvo(
      _edicaoBNova(),
      id: 'antigo',
      codigo: '271026-01',
      atualizadoEm: DateTime(2026, 10, 27),
    );
    final recente = orcamentoSalvo(
      edicaoC,
      id: 'recente',
      atualizadoEm: DateTime(2026, 10, 29),
    );
    await repositorio.inserir(antigo);
    await repositorio.inserir(recente);

    expect(await repositorio.listarResumos(), [recente, antigo]);
  });

  test('código e chave repetidos não são gravados', () async {
    await repositorio.inserir(orcamentoC);
    expect(
      () => repositorio.inserir(orcamentoC.copyWith(id: 'outro')),
      throwsA(isA<DatabaseException>()),
    );
    expect(await repositorio.listarResumos(), hasLength(1));
  });

  test(
    'atualizar troca a revisão, os itens e a chave na mesma linha',
    () async {
      await repositorio.inserir(orcamentoC);
      final revisao2 = orcamentoSalvo(edicaoB).copyWith(
        id: orcamentoC.id,
        codigo: orcamentoC.codigo,
        revisao: 2,
        chaveFinalizacao: 'chave-da-edicao',
        atualizadoEm: DateTime(2026, 10, 30),
      );

      await repositorio.atualizar(revisao2);

      expect(await repositorio.buscarPorId(orcamentoC.id), revisao2);
      expect(
        await repositorio.buscarPorChaveFinalizacao('chave-da-edicao'),
        revisao2,
      );
      expect(
        await repositorio.buscarPorChaveFinalizacao(edicaoC.chaveFinalizacao),
        isNull,
      );
      expect(await _contar(banco, 'itens_orcamento'), 1);
      expect(await _contar(banco, 'pecas_orcamento'), 1);
    },
  );

  test('atualizar um orçamento inexistente falha sem gravar', () async {
    await expectLater(
      repositorio.atualizar(orcamentoC),
      throwsA(isA<StateError>()),
    );
    expect(await _contar(banco, 'itens_orcamento'), 0);
  });

  test('excluir apaga itens e peças, nunca materiais nem clientes', () async {
    await SqliteMaterialRepository(banco).salvar(granito);
    await SqliteClienteRepository(banco).salvar(clienteTeste);
    await repositorio.inserir(orcamentoC);
    await repositorio.inserir(
      orcamentoSalvo(_edicaoBNova(), id: 'outro', codigo: '281026-04'),
    );

    await repositorio.excluir(orcamentoC.id);

    expect(await repositorio.buscarPorId(orcamentoC.id), isNull);
    expect(await _contar(banco, 'itens_orcamento'), 1);
    expect(await _contar(banco, 'pecas_orcamento'), 1);
    expect(await _contar(banco, 'materiais'), 1);
    expect(await _contar(banco, 'clientes'), 1);
  });

  test('inserir é atômico: falha nas peças não deixa o orçamento', () async {
    // A mesma peça duas vezes viola a chave primária de pecas_orcamento.
    final item = itemB.copyWith(
      pecas: [itemB.pecas.single, itemB.pecas.single],
    );
    final invalido = orcamentoSalvo(edicaoB.copyWith(itens: [item]));

    await expectLater(
      repositorio.inserir(invalido),
      throwsA(isA<DatabaseException>()),
    );
    expect(await repositorio.listarResumos(), isEmpty);
  });

  test('um orçamento salvo não muda quando o cadastro muda', () async {
    final materiais = SqliteMaterialRepository(banco);
    await materiais.salvar(mdf);
    await repositorio.inserir(orcamentoSalvo(edicaoB));

    await materiais.salvar(
      mdf.copyWith(precoReferencia: const Dinheiro(10000)),
    );
    await materiais.inativar(mdf.id);

    final lido = (await repositorio.listarResumos()).single;
    expect(
      lido.itens.single.pecas.single.material.precoAplicado,
      const Dinheiro(9000),
    );
    expect(lido.totalGeral, Dinheiro.parse('644,40'));
  });
}
