import 'dart:io';

import 'package:fera_metalurgica_app/core/di/banco_de_dados.dart';
import 'package:fera_metalurgica_app/core/di/esquema_banco.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../mocks/banco_de_teste.dart';

Map<String, Object?> _orcamento(String id, {String? codigo, String? chave}) => {
  'id': id,
  'codigo': codigo ?? 'codigo-$id',
  'revisao': 1,
  'chave_finalizacao': chave ?? 'chave-$id',
  'criado_em': 0,
  'atualizado_em': 0,
  'status': 'criado',
  'cliente_json': '{}',
  'emitente_json': '{}',
  'insumos': 0,
  'impostos': 0,
  'combustivel': 0,
  'outros': 0,
  'desconto': 0,
  'totais_json': '{}',
  'versao_calculo': 1,
};

Map<String, Object?> _item(String id, String orcamentoId) => {
  'id': id,
  'orcamento_id': orcamentoId,
  'ordem': 0,
  'descricao': 'Produto',
  'quantidade_produtos': 1,
  'preco_base': 0,
};

Map<String, Object?> _peca(String id, String itemId) => {
  'id': id,
  'item_id': itemId,
  'ordem': 0,
  'descricao': 'Peça',
  'quantidade_por_produto': 1,
  'material_nome': 'MDF',
  'material_unidade': 'm2',
  'material_preco_referencia_copiado': 9000,
  'material_preco_aplicado': 9000,
  'comprimento': 12000,
  'largura': 6000,
};

Future<int> _contar(Database banco, String tabela) async {
  final linhas = await banco.rawQuery('SELECT COUNT(*) AS n FROM $tabela');
  return linhas.single['n']! as int;
}

void main() {
  late Database banco;

  setUp(() async => banco = await bancoDeTeste());
  tearDown(() => banco.close());

  test('cria o esquema na versão atual, com todas as tabelas', () async {
    expect(await banco.getVersion(), versaoEsquema);
    final tabelas = await banco.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    );
    expect(
      tabelas.map((t) => t['name']),
      containsAll(<String>[
        'materiais',
        'empresa',
        'clientes',
        'orcamentos',
        'itens_orcamento',
        'pecas_orcamento',
        'sequencias',
        'tarefas',
        'preferencias',
      ]),
    );
  });

  test('migra da versão 1 para a 2 sem perder dados (D-45)', () async {
    final pasta = await Directory.systemTemp.createTemp('fera_migracao');
    addTearDown(() => pasta.delete(recursive: true));
    final caminho = '${pasta.path}${Platform.pathSeparator}v1.db';
    final antigo = await databaseFactoryFfiNoIsolate.openDatabase(
      caminho,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) => db.execute(
          'CREATE TABLE sequencias (dia TEXT PRIMARY KEY, ultima INTEGER)',
        ),
      ),
    );
    await antigo.insert('sequencias', {'dia': '2026-11-11', 'ultima': 3});
    await antigo.close();

    final (:banco, :novo) = await abrirBancoDeDados(
      databaseFactoryFfiNoIsolate,
      caminho,
      instanciaUnica: false,
    );
    addTearDown(banco.close);

    expect(novo, isFalse);
    expect(await banco.getVersion(), versaoEsquema);
    expect(await _contar(banco, 'sequencias'), 1);
    expect(await _contar(banco, 'preferencias'), 0);
  });

  test('liga as chaves estrangeiras', () async {
    final pragma = await banco.rawQuery('PRAGMA foreign_keys');
    expect(pragma.single.values.single, 1);
  });

  test('código e chave de finalização são únicos', () async {
    await banco.insert('orcamentos', _orcamento('a', codigo: 'X', chave: 'K'));
    expect(
      () => banco.insert('orcamentos', _orcamento('b', codigo: 'X')),
      throwsA(isA<DatabaseException>()),
    );
    expect(
      () => banco.insert('orcamentos', _orcamento('c', chave: 'K')),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('documento do cliente é único', () async {
    Map<String, Object?> cliente(String id) => {
      'id': id,
      'nome': 'Cliente $id',
      'documento': '52998224725',
      'celular': '41999998888',
      'logradouro': 'Rua',
      'numero': '1',
      'bairro': 'Centro',
      'cidade': 'Curitiba',
      'uf': 'PR',
    };
    await banco.insert('clientes', cliente('a'));
    expect(
      () => banco.insert('clientes', cliente('b')),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('excluir o orçamento exclui itens e peças em cascata', () async {
    await banco.insert('orcamentos', _orcamento('o1'));
    await banco.insert('orcamentos', _orcamento('o2'));
    await banco.insert('itens_orcamento', _item('i1', 'o1'));
    await banco.insert('itens_orcamento', _item('i2', 'o2'));
    await banco.insert('pecas_orcamento', _peca('p1', 'i1'));
    await banco.insert('pecas_orcamento', _peca('p2', 'i2'));

    await banco.delete('orcamentos', where: 'id = ?', whereArgs: ['o1']);

    expect(await _contar(banco, 'itens_orcamento'), 1);
    expect(await _contar(banco, 'pecas_orcamento'), 1);
  });
}
