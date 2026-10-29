import 'package:fera_metalurgica_app/core/di/banco_de_dados.dart';
import 'package:fera_metalurgica_app/core/domain/documento.dart';
import 'package:fera_metalurgica_app/core/utils/linha_sql.dart';
import 'package:fera_metalurgica_app/core/utils/texto_busca.dart';
import 'package:fera_metalurgica_app/features/clientes/domain/cliente.dart';
import 'package:fera_metalurgica_app/features/clientes/domain/cliente_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sqflite/sqflite.dart';

part 'sqlite_cliente_repository.g.dart';

/// [ClienteRepository] no SQLite (tabela `clientes`). O documento
/// normalizado é `UNIQUE` no esquema: salvar um cliente com o documento de
/// outro lança `DatabaseException`.
class SqliteClienteRepository implements ClienteRepository {
  /// Cria o repositório sobre [_executor] (o banco ou uma transação).
  const SqliteClienteRepository(this._executor);

  final DatabaseExecutor _executor;

  static const String _tabela = 'clientes';

  @override
  Future<Cliente?> buscarPorDocumento(Documento documento) async {
    final linhas = await _executor.query(
      _tabela,
      where: 'documento = ?',
      whereArgs: [documento.valorNormalizado],
    );
    return linhas.isEmpty ? null : _deLinha(linhas.single);
  }

  /// Filtra em Dart, sem diferenciar maiúsculas nem acentos: o `LIKE` do
  /// SQLite só ignora maiúsculas em ASCII, e o cadastro de uma instalação é
  /// pequeno.
  @override
  Future<List<Cliente>> pesquisar(String termo) async {
    final texto = normalizarParaBusca(termo.trim());
    final digitos = texto.replaceAll(RegExp(r'\D'), '');
    final todos = (await _executor.query(_tabela)).map(_deLinha);
    return todos.where((c) {
      if (texto.isEmpty) return true;
      if (normalizarParaBusca(c.nome).contains(texto)) return true;
      if (digitos.isEmpty) return false;
      return c.documento.valorNormalizado.contains(digitos) ||
          c.celular.replaceAll(RegExp(r'\D'), '').contains(digitos);
    }).toList()..sort((a, b) => compararNomes(a.nome, b.nome));
  }

  /// Cria ou atualiza pelo `id`. Um documento já usado por outro cliente
  /// viola a unicidade e lança `DatabaseException`.
  @override
  Future<void> salvar(Cliente cliente) async {
    final linha = _paraLinha(cliente);
    final atualizadas = await _executor.update(
      _tabela,
      linha,
      where: 'id = ?',
      whereArgs: [cliente.id],
    );
    if (atualizadas == 0) await _executor.insert(_tabela, linha);
  }

  static Map<String, Object?> _paraLinha(Cliente cliente) => {
    'id': cliente.id,
    'nome': cliente.nome,
    'documento': cliente.documento.valorNormalizado,
    'celular': cliente.celular,
    ...enderecoParaLinha(cliente.endereco),
  };

  static Cliente _deLinha(Map<String, Object?> linha) => Cliente(
    id: linha['id']! as String,
    nome: linha['nome']! as String,
    documento: Documento(linha['documento']! as String),
    celular: linha['celular']! as String,
    endereco: enderecoDaLinha(linha),
  );
}

/// Provider do [ClienteRepository] do app.
@riverpod
ClienteRepository clienteRepository(Ref ref) =>
    SqliteClienteRepository(ref.watch(bancoDeDadosProvider));
