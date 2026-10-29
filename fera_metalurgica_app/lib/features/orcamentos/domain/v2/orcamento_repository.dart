import 'package:fera_metalurgica_app/features/orcamentos/domain/v2/orcamento.dart';

/// Contrato de persistência dos orçamentos v2 (prompt §7, D-30). O orçamento
/// é o agregado: grava e exclui junto seus itens e peças. Não existem
/// repositórios de produto nem de peça.
///
/// Não crie uma segunda implementação/local de acesso a orçamentos: toda
/// leitura/escrita de orçamentos passa por aqui.
abstract class OrcamentoRepository {
  /// Todos os orçamentos salvos, com os totais gravados, do
  /// `atualizadoEm` mais recente para o mais antigo.
  Future<List<Orcamento>> listarResumos();

  /// O orçamento de identificador [id], ou `null` se não existir.
  Future<Orcamento?> buscarPorId(String id);

  /// O orçamento gravado com a [chave] de finalização, ou `null`. Usado
  /// para não gravar duas vezes no clique duplo.
  Future<Orcamento?> buscarPorChaveFinalizacao(String chave);

  /// Grava um orçamento novo, com itens, peças e totais. Código e chave de
  /// finalização são únicos.
  Future<void> inserir(Orcamento orcamento);

  /// Substitui o orçamento de mesmo id pela nova revisão (D-30), com itens,
  /// peças e totais.
  Future<void> atualizar(Orcamento orcamento);

  /// Exclui o orçamento [id] com seus itens e peças; nunca materiais nem
  /// clientes. O código excluído não é reutilizado.
  Future<void> excluir(String id);
}
