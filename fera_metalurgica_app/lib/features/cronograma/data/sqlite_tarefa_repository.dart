import 'package:fera_metalurgica_app/core/di/banco_de_dados.dart';
import 'package:fera_metalurgica_app/core/utils/linha_sql.dart';
import 'package:fera_metalurgica_app/features/cronograma/domain/tarefa.dart';
import 'package:fera_metalurgica_app/features/cronograma/domain/tarefa_repository.dart';
import 'package:fera_metalurgica_app/features/cronograma/domain/tipo_tarefa.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sqflite/sqflite.dart';

part 'sqlite_tarefa_repository.g.dart';

/// [TarefaRepository] no SQLite (tabela `tarefas`).
class SqliteTarefaRepository implements TarefaRepository {
  /// Cria o repositório sobre [_executor] (o banco ou uma transação).
  const SqliteTarefaRepository(this._executor);

  final DatabaseExecutor _executor;

  static const String _tabela = 'tarefas';

  @override
  Future<List<Tarefa>> getAll() async {
    final linhas = await _executor.query(_tabela, orderBy: 'data');
    return linhas.map(_deLinha).toList();
  }

  @override
  Future<void> save(Tarefa tarefa) => _executor.insert(
    _tabela,
    _paraLinha(tarefa),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );

  @override
  Future<void> delete(String id) =>
      _executor.delete(_tabela, where: 'id = ?', whereArgs: [id]);

  static Map<String, Object?> _paraLinha(Tarefa tarefa) => {
    'id': tarefa.id,
    'titulo': tarefa.titulo,
    'data': dataParaLinha(tarefa.data),
    'tipo': tarefa.tipo.name,
    'concluida': tarefa.concluida ? 1 : 0,
    'descricao': tarefa.descricao,
    'orcamento_id': tarefa.orcamentoId,
  };

  static Tarefa _deLinha(Map<String, Object?> linha) => Tarefa(
    id: linha['id']! as String,
    titulo: linha['titulo']! as String,
    data: dataDaLinha(linha['data']),
    tipo: TipoTarefa.values.byName(linha['tipo']! as String),
    concluida: linha['concluida'] == 1,
    descricao: linha['descricao'] as String?,
    orcamentoId: linha['orcamento_id'] as String?,
  );
}

/// Provider do [TarefaRepository] do app.
@riverpod
TarefaRepository tarefaRepository(Ref ref) =>
    SqliteTarefaRepository(ref.watch(bancoDeDadosProvider));
