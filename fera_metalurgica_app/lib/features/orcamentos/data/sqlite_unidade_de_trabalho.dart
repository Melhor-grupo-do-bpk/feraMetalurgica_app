import 'package:fera_metalurgica_app/core/di/banco_de_dados.dart';
import 'package:fera_metalurgica_app/features/clientes/clientes.dart';
import 'package:fera_metalurgica_app/features/orcamentos/data/sqlite_orcamento_repository.dart';
import 'package:fera_metalurgica_app/features/orcamentos/data/sqlite_sequencia_repository.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/orcamento_repository.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/sequencia_repository.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/unidade_de_trabalho.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sqflite/sqflite.dart';

part 'sqlite_unidade_de_trabalho.g.dart';

/// [UnidadeDeTrabalho] com uma transação real do SQLite (D-27): os
/// repositórios entregues à operação são criados sobre a transação, e um
/// erro na operação desfaz tudo.
class SqliteUnidadeDeTrabalho implements UnidadeDeTrabalho {
  /// Cria a unidade de trabalho sobre o [_banco].
  const SqliteUnidadeDeTrabalho(this._banco);

  final Database _banco;

  @override
  Future<T> executarEmTransacao<T>(
    Future<T> Function(RepositoriosTransacao repos) operacao,
  ) => _banco.transaction((txn) => operacao(_RepositoriosSqlite(txn)));
}

class _RepositoriosSqlite implements RepositoriosTransacao {
  _RepositoriosSqlite(Transaction txn)
    : clientes = SqliteClienteRepository(txn),
      orcamentos = SqliteOrcamentoRepository(txn),
      sequencias = SqliteSequenciaRepository(txn);

  @override
  final ClienteRepository clientes;

  @override
  final OrcamentoRepository orcamentos;

  @override
  final SequenciaRepository sequencias;
}

/// Provider da [UnidadeDeTrabalho] do app.
@riverpod
UnidadeDeTrabalho unidadeDeTrabalho(Ref ref) =>
    SqliteUnidadeDeTrabalho(ref.watch(bancoDeDadosProvider));
