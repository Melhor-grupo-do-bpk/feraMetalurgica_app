import 'package:fera_metalurgica_app/core/di/banco_de_dados.dart';
import 'package:fera_metalurgica_app/core/domain/documento.dart';
import 'package:fera_metalurgica_app/core/utils/linha_sql.dart';
import 'package:fera_metalurgica_app/features/empresa/domain/empresa.dart';
import 'package:fera_metalurgica_app/features/empresa/domain/empresa_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sqflite/sqflite.dart';

part 'sqlite_empresa_repository.g.dart';

/// [EmpresaRepository] no SQLite (tabela `empresa`, com uma linha só).
class SqliteEmpresaRepository implements EmpresaRepository {
  /// Cria o repositório sobre [_executor] (o banco ou uma transação).
  const SqliteEmpresaRepository(this._executor);

  final DatabaseExecutor _executor;

  static const String _tabela = 'empresa';

  @override
  Future<Empresa?> obter() async {
    final linhas = await _executor.query(_tabela, limit: 1);
    return linhas.isEmpty ? null : _deLinha(linhas.single);
  }

  /// Apaga o emitente anterior e grava [empresa], numa transação quando
  /// recebe o banco, para garantir um emitente só.
  @override
  Future<void> salvar(Empresa empresa) async {
    Future<void> gravar(DatabaseExecutor executor) async {
      await executor.delete(_tabela);
      await executor.insert(_tabela, _paraLinha(empresa));
    }

    final executor = _executor;
    if (executor is Database) {
      await executor.transaction(gravar);
    } else {
      await gravar(executor);
    }
  }

  static Map<String, Object?> _paraLinha(Empresa empresa) => {
    'id': empresa.id,
    'nome_razao_social': empresa.nomeRazaoSocial,
    'documento': empresa.documento.valorNormalizado,
    'telefone': empresa.telefone,
    'email': empresa.email,
    ...enderecoParaLinha(empresa.endereco),
  };

  static Empresa _deLinha(Map<String, Object?> linha) => Empresa(
    id: linha['id']! as String,
    nomeRazaoSocial: linha['nome_razao_social']! as String,
    documento: Documento(linha['documento']! as String),
    telefone: linha['telefone']! as String,
    email: linha['email'] as String?,
    endereco: enderecoDaLinha(linha),
  );
}

/// Provider do [EmpresaRepository] do app.
@riverpod
EmpresaRepository empresaRepository(Ref ref) =>
    SqliteEmpresaRepository(ref.watch(bancoDeDadosProvider));
