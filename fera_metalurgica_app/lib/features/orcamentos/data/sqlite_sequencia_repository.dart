import 'package:fera_metalurgica_app/features/orcamentos/domain/v2/sequencia_repository.dart';
import 'package:sqflite/sqflite.dart';

/// [SequenciaRepository] no SQLite: um contador por dia na tabela
/// `sequencias`, que só cresce. Rode na transação da `UnidadeDeTrabalho`,
/// junto com a gravação do orçamento, para que uma falha devolva o número.
class SqliteSequenciaRepository implements SequenciaRepository {
  /// Cria o repositório sobre [_executor] (normalmente uma transação).
  const SqliteSequenciaRepository(this._executor);

  final DatabaseExecutor _executor;

  @override
  Future<int> proximaDoDia(DateTime data) async {
    final dia = chaveDoDia(data);
    await _executor.rawInsert(
      'INSERT INTO sequencias (dia, ultima) VALUES (?, 1) '
      'ON CONFLICT (dia) DO UPDATE SET ultima = ultima + 1',
      [dia],
    );
    final linhas = await _executor.query(
      'sequencias',
      columns: ['ultima'],
      where: 'dia = ?',
      whereArgs: [dia],
    );
    return linhas.single['ultima']! as int;
  }

  /// A data local de [data] em `AAAA-MM-DD` (a hora não conta).
  static String chaveDoDia(DateTime data) {
    String dois(int n) => n.toString().padLeft(2, '0');
    return '${data.year.toString().padLeft(4, '0')}-'
        '${dois(data.month)}-${dois(data.day)}';
  }
}
