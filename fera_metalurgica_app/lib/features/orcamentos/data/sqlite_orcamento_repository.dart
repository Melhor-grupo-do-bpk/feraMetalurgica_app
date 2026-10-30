import 'dart:convert';

import 'package:fera_metalurgica_app/core/di/banco_de_dados.dart';
import 'package:fera_metalurgica_app/core/domain/dinheiro.dart';
import 'package:fera_metalurgica_app/core/domain/medida_cm.dart';
import 'package:fera_metalurgica_app/core/domain/unidade_cobranca.dart';
import 'package:fera_metalurgica_app/core/utils/linha_sql.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/v2/cliente_snapshot.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/v2/empresa_snapshot.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/v2/item_orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/v2/material_snapshot.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/v2/orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/v2/orcamento_repository.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/v2/peca_orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/v2/resultado_orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/v2/status_orcamento.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sqflite/sqflite.dart';

part 'sqlite_orcamento_repository.g.dart';

/// [OrcamentoRepository] no SQLite: o orçamento em `orcamentos` (com as
/// cópias de cliente e emitente e os totais em JSON), os produtos em
/// `itens_orcamento` e as peças, com o material copiado, em
/// `pecas_orcamento`, na ordem exibida.
///
/// Gravar um orçamento grava o agregado inteiro de forma atômica: numa
/// transação própria quando recebe o banco, ou na transação da
/// `UnidadeDeTrabalho`.
class SqliteOrcamentoRepository implements OrcamentoRepository {
  /// Cria o repositório sobre [_executor] (o banco ou uma transação).
  const SqliteOrcamentoRepository(this._executor);

  final DatabaseExecutor _executor;

  static const String _orcamentos = 'orcamentos';
  static const String _itens = 'itens_orcamento';
  static const String _pecas = 'pecas_orcamento';

  @override
  Future<List<Orcamento>> listarResumos() =>
      _consultar(orderBy: 'atualizado_em DESC');

  @override
  Future<Orcamento?> buscarPorId(String id) async =>
      (await _consultar(where: 'id = ?', whereArgs: [id])).firstOrNull;

  @override
  Future<Orcamento?> buscarPorChaveFinalizacao(String chave) async =>
      (await _consultar(
        where: 'chave_finalizacao = ?',
        whereArgs: [chave],
      )).firstOrNull;

  @override
  Future<void> inserir(Orcamento orcamento) =>
      emTransacao(_executor, (executor) async {
        await executor.insert(_orcamentos, _orcamentoParaLinha(orcamento));
        await _inserirItens(executor, orcamento);
      });

  /// Troca a linha do orçamento e recria itens e peças. A chave de
  /// finalização da nova revisão substitui a anterior na mesma linha.
  /// Lança [StateError] se o orçamento não existir.
  @override
  Future<void> atualizar(Orcamento orcamento) =>
      emTransacao(_executor, (executor) async {
        final atualizadas = await executor.update(
          _orcamentos,
          _orcamentoParaLinha(orcamento),
          where: 'id = ?',
          whereArgs: [orcamento.id],
        );
        if (atualizadas == 0) {
          throw StateError('Orçamento ${orcamento.id} não existe');
        }
        // As peças saem em cascata.
        await executor.delete(
          _itens,
          where: 'orcamento_id = ?',
          whereArgs: [orcamento.id],
        );
        await _inserirItens(executor, orcamento);
      });

  @override
  Future<void> excluir(String id) =>
      _executor.delete(_orcamentos, where: 'id = ?', whereArgs: [id]);

  Future<void> _inserirItens(
    DatabaseExecutor executor,
    Orcamento orcamento,
  ) async {
    final lote = executor.batch();
    for (final (ordemItem, item) in orcamento.itens.indexed) {
      lote.insert(_itens, _itemParaLinha(item, orcamento.id, ordemItem));
      for (final (ordemPeca, peca) in item.pecas.indexed) {
        lote.insert(_pecas, _pecaParaLinha(peca, item.id, ordemPeca));
      }
    }
    await lote.commit(noResult: true);
  }

  /// Lê os orçamentos e monta os agregados com duas consultas a mais (itens
  /// e peças de todos eles), em vez de uma por orçamento.
  Future<List<Orcamento>> _consultar({
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
  }) async {
    final linhas = await _executor.query(
      _orcamentos,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
    );
    if (linhas.isEmpty) return const [];

    final ids = [for (final l in linhas) l['id']! as String];
    final marcadores = List.filled(ids.length, '?').join(', ');
    final linhasItens = await _executor.query(
      _itens,
      where: 'orcamento_id IN ($marcadores)',
      whereArgs: ids,
      orderBy: 'ordem',
    );
    final linhasPecas = await _executor.rawQuery(
      'SELECT p.* FROM $_pecas p JOIN $_itens i ON i.id = p.item_id '
      'WHERE i.orcamento_id IN ($marcadores) ORDER BY p.ordem',
      ids,
    );

    final pecasPorItem = <String, List<PecaOrcamento>>{};
    for (final linha in linhasPecas) {
      (pecasPorItem[linha['item_id']! as String] ??= []).add(
        _pecaDeLinha(linha),
      );
    }
    final itensPorOrcamento = <String, List<ItemOrcamento>>{};
    for (final linha in linhasItens) {
      final id = linha['id']! as String;
      (itensPorOrcamento[linha['orcamento_id']! as String] ??= []).add(
        _itemDeLinha(linha, pecasPorItem[id] ?? const []),
      );
    }
    return [
      for (final linha in linhas)
        _orcamentoDeLinha(
          linha,
          itensPorOrcamento[linha['id']! as String] ?? const [],
        ),
    ];
  }

  static Map<String, Object?> _orcamentoParaLinha(Orcamento o) {
    final enviadoEm = o.enviadoEm;
    return {
      'id': o.id,
      'codigo': o.codigo,
      'revisao': o.revisao,
      'chave_finalizacao': o.chaveFinalizacao,
      'criado_em': dataParaLinha(o.criadoEm),
      'atualizado_em': dataParaLinha(o.atualizadoEm),
      'enviado_em': enviadoEm == null ? null : dataParaLinha(enviadoEm),
      'status': o.status.name,
      'cliente_json': jsonEncode(o.cliente.toJson()),
      'emitente_json': jsonEncode(o.emitente.toJson()),
      'insumos': o.insumos.centavos,
      'impostos': o.impostos.centavos,
      'combustivel': o.combustivel.centavos,
      'outros': o.outros.centavos,
      'outros_descricao': o.outrosDescricao,
      'desconto': o.desconto.centavos,
      'validade_dias': o.validadeDias,
      'observacoes': o.observacoes,
      'totais_json': jsonEncode(o.totais.toJson()),
      'versao_calculo': o.versaoCalculo,
    };
  }

  static Orcamento _orcamentoDeLinha(
    Map<String, Object?> linha,
    List<ItemOrcamento> itens,
  ) {
    Map<String, dynamic> json(String coluna) =>
        jsonDecode(linha[coluna]! as String) as Map<String, dynamic>;
    final enviadoEm = linha['enviado_em'];
    return Orcamento(
      id: linha['id']! as String,
      codigo: linha['codigo']! as String,
      revisao: linha['revisao']! as int,
      chaveFinalizacao: linha['chave_finalizacao']! as String,
      criadoEm: dataDaLinha(linha['criado_em']),
      atualizadoEm: dataDaLinha(linha['atualizado_em']),
      enviadoEm: enviadoEm == null ? null : dataDaLinha(enviadoEm),
      status: StatusOrcamento.values.byName(linha['status']! as String),
      cliente: ClienteSnapshot.fromJson(json('cliente_json')),
      emitente: EmpresaSnapshot.fromJson(json('emitente_json')),
      itens: itens,
      insumos: Dinheiro(linha['insumos']! as int),
      impostos: Dinheiro(linha['impostos']! as int),
      combustivel: Dinheiro(linha['combustivel']! as int),
      outros: Dinheiro(linha['outros']! as int),
      outrosDescricao: linha['outros_descricao'] as String?,
      desconto: Dinheiro(linha['desconto']! as int),
      validadeDias: linha['validade_dias'] as int?,
      observacoes: linha['observacoes'] as String?,
      totais: ResultadoOrcamento.fromJson(json('totais_json')),
      versaoCalculo: linha['versao_calculo']! as int,
    );
  }

  static Map<String, Object?> _itemParaLinha(
    ItemOrcamento item,
    String orcamentoId,
    int ordem,
  ) => {
    'id': item.id,
    'orcamento_id': orcamentoId,
    'ordem': ordem,
    'descricao': item.descricao,
    'quantidade_produtos': item.quantidadeProdutos,
    'preco_base': item.precoBase.centavos,
    'observacoes': item.observacoes,
  };

  static ItemOrcamento _itemDeLinha(
    Map<String, Object?> linha,
    List<PecaOrcamento> pecas,
  ) => ItemOrcamento(
    id: linha['id']! as String,
    descricao: linha['descricao']! as String,
    quantidadeProdutos: linha['quantidade_produtos']! as int,
    precoBase: Dinheiro(linha['preco_base']! as int),
    pecas: pecas,
    observacoes: linha['observacoes'] as String?,
  );

  static Map<String, Object?> _pecaParaLinha(
    PecaOrcamento peca,
    String itemId,
    int ordem,
  ) => {
    'id': peca.id,
    'item_id': itemId,
    'ordem': ordem,
    'descricao': peca.descricao,
    'quantidade_por_produto': peca.quantidadePorProduto,
    'material_nome': peca.material.nome,
    'material_unidade': peca.material.unidade.name,
    'material_preco_referencia_copiado':
        peca.material.precoReferenciaCopiado.centavos,
    'material_preco_aplicado': peca.material.precoAplicado.centavos,
    'material_origem_id': peca.material.materialOrigemId,
    'comprimento': peca.comprimentoCm.centesimos,
    'largura': peca.larguraCm.centesimos,
    'espessura': peca.espessuraCm?.centesimos,
    'observacoes': peca.observacoes,
  };

  static PecaOrcamento _pecaDeLinha(Map<String, Object?> linha) {
    final espessura = linha['espessura'] as int?;
    return PecaOrcamento(
      id: linha['id']! as String,
      descricao: linha['descricao']! as String,
      quantidadePorProduto: linha['quantidade_por_produto']! as int,
      material: MaterialSnapshot(
        nome: linha['material_nome']! as String,
        unidade: UnidadeCobranca.values.byName(
          linha['material_unidade']! as String,
        ),
        precoReferenciaCopiado: Dinheiro(
          linha['material_preco_referencia_copiado']! as int,
        ),
        precoAplicado: Dinheiro(linha['material_preco_aplicado']! as int),
        materialOrigemId: linha['material_origem_id'] as String?,
      ),
      comprimentoCm: MedidaCm(linha['comprimento']! as int),
      larguraCm: MedidaCm(linha['largura']! as int),
      espessuraCm: espessura == null ? null : MedidaCm(espessura),
      observacoes: linha['observacoes'] as String?,
    );
  }
}

/// Provider do [OrcamentoRepository] do app (fora de transação: leituras,
/// exclusão e mudança de status).
@riverpod
OrcamentoRepository orcamentoRepositoryV2(Ref ref) =>
    SqliteOrcamentoRepository(ref.watch(bancoDeDadosProvider));
