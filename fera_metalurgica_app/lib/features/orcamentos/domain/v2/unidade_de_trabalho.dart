import 'package:fera_metalurgica_app/features/clientes/clientes.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/v2/orcamento_repository.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/v2/sequencia_repository.dart';

/// Executa gravações de vários registros numa transação (prompt §7 e §8,
/// D-27): tudo confirma ou tudo desfaz.
///
/// A operação recebe os repositórios ligados à transação, explicitamente,
/// sem estado implícito: a implementação cria cada repositório com o
/// executor da transação.
abstract class UnidadeDeTrabalho {
  /// Abre uma transação, executa [operacao] com os repositórios dela e
  /// confirma. Se [operacao] lançar, desfaz tudo e relança o erro.
  Future<T> executarEmTransacao<T>(
    Future<T> Function(RepositoriosTransacao repos) operacao,
  );
}

/// Repositórios usados na gravação do orçamento, todos ligados à mesma
/// transação. Válidos só durante a `operacao` de
/// [UnidadeDeTrabalho.executarEmTransacao].
abstract class RepositoriosTransacao {
  /// Clientes (resolver, criar ou atualizar pelo documento).
  ClienteRepository get clientes;

  /// Orçamentos (inserir ou atualizar a revisão).
  OrcamentoRepository get orcamentos;

  /// Sequência diária do código.
  SequenciaRepository get sequencias;
}
