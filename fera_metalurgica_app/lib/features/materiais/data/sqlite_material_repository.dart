import 'package:fera_metalurgica_app/core/di/banco_de_dados.dart';
import 'package:fera_metalurgica_app/core/domain/dinheiro.dart';
import 'package:fera_metalurgica_app/core/domain/unidade_cobranca.dart';
import 'package:fera_metalurgica_app/core/utils/texto_busca.dart';
import 'package:fera_metalurgica_app/features/materiais/domain/material.dart';
import 'package:fera_metalurgica_app/features/materiais/domain/material_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sqflite/sqflite.dart';

part 'sqlite_material_repository.g.dart';

/// [MaterialRepository] no SQLite (tabela `materiais`).
class SqliteMaterialRepository implements MaterialRepository {
  /// Cria o repositório sobre [_executor] (o banco ou uma transação).
  const SqliteMaterialRepository(this._executor);

  final DatabaseExecutor _executor;

  static const String _tabela = 'materiais';

  @override
  Future<List<Material>> listarAtivos({String? filtro}) async {
    final termo = normalizarParaBusca(filtro?.trim() ?? '');
    final ativos = await _listar(where: 'ativo = 1');
    if (termo.isEmpty) return ativos;
    return ativos
        .where((m) => normalizarParaBusca(m.nome).contains(termo))
        .toList();
  }

  @override
  Future<List<Material>> listarTodos() => _listar();

  @override
  Future<Material?> buscarPorId(String id) async {
    final linhas = await _executor.query(
      _tabela,
      where: 'id = ?',
      whereArgs: [id],
    );
    return linhas.isEmpty ? null : _deLinha(linhas.single);
  }

  @override
  Future<void> salvar(Material material) => _executor.insert(
    _tabela,
    _paraLinha(material),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );

  @override
  Future<void> inativar(String id) => _marcarAtivo(id, ativo: false);

  @override
  Future<void> reativar(String id) => _marcarAtivo(id, ativo: true);

  Future<void> _marcarAtivo(String id, {required bool ativo}) =>
      _executor.update(
        _tabela,
        {'ativo': ativo ? 1 : 0},
        where: 'id = ?',
        whereArgs: [id],
      );

  /// Ordena por nome sem diferenciar maiúsculas nem acentos (o `ORDER BY`
  /// do SQLite compara bytes).
  Future<List<Material>> _listar({String? where}) async {
    final linhas = await _executor.query(_tabela, where: where);
    return linhas.map(_deLinha).toList()
      ..sort((a, b) => compararNomes(a.nome, b.nome));
  }

  static Map<String, Object?> _paraLinha(Material material) => {
    'id': material.id,
    'nome': material.nome,
    'unidade': material.unidade.name,
    'preco_referencia': material.precoReferencia.centavos,
    'ativo': material.ativo ? 1 : 0,
  };

  static Material _deLinha(Map<String, Object?> linha) => Material(
    id: linha['id']! as String,
    nome: linha['nome']! as String,
    unidade: UnidadeCobranca.values.byName(linha['unidade']! as String),
    precoReferencia: Dinheiro(linha['preco_referencia']! as int),
    ativo: linha['ativo'] == 1,
  );
}

/// Provider do [MaterialRepository] do app.
@riverpod
MaterialRepository materialRepository(Ref ref) =>
    SqliteMaterialRepository(ref.watch(bancoDeDadosProvider));
