import 'package:fera_metalurgica_app/core/domain/dinheiro.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/cliente_snapshot.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/empresa_snapshot.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/item_orcamento.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'orcamento_em_edicao.freezed.dart';
part 'orcamento_em_edicao.g.dart';

/// Sessão do wizard, só em memória (prompt §7; sem rascunho persistido).
/// Pode estar incompleta. Peças e itens só entram nas listas depois de
/// validados; o texto de formulários incompletos é estado da interface.
///
/// Não tem totais: o resumo é recalculado pela `CalculadoraOrcamento`, e os
/// totais definitivos são gravados ao salvar. Na edição de um orçamento
/// salvo (D-30), [orcamentoOrigemId], [codigo] e [revisao] vêm dele.
@freezed
abstract class OrcamentoEmEdicao with _$OrcamentoEmEdicao {
  /// Cria um [OrcamentoEmEdicao].
  const factory OrcamentoEmEdicao({
    /// Chave idempotente da gravação, gerada ao iniciar a sessão.
    required String chaveFinalizacao,

    /// Cópia da empresa emitente, feita ao iniciar.
    required EmpresaSnapshot emitente,

    /// Cópia editável do cliente; `null` até a etapa 1 ser preenchida.
    ClienteSnapshot? cliente,

    /// Produtos já validados, na ordem exibida.
    @Default(<ItemOrcamento>[]) List<ItemOrcamento> itens,

    /// Insumos.
    @DinheiroJsonConverter() @Default(Dinheiro.zero) Dinheiro insumos,

    /// Impostos.
    @DinheiroJsonConverter() @Default(Dinheiro.zero) Dinheiro impostos,

    /// Combustível.
    @DinheiroJsonConverter() @Default(Dinheiro.zero) Dinheiro combustivel,

    /// Outros valores.
    @DinheiroJsonConverter() @Default(Dinheiro.zero) Dinheiro outros,

    /// Descrição de [outros].
    String? outrosDescricao,

    /// Desconto.
    @DinheiroJsonConverter() @Default(Dinheiro.zero) Dinheiro desconto,

    /// Validade em dias corridos.
    int? validadeDias,

    /// Observações gerais.
    String? observacoes,

    /// Id do orçamento salvo em edição; `null` num orçamento novo.
    String? orcamentoOrigemId,

    /// Código do orçamento em edição; `null` num novo (gerado ao salvar).
    String? codigo,

    /// Revisão do orçamento em edição, antes de salvar; `null` num novo.
    int? revisao,
  }) = _OrcamentoEmEdicao;

  const OrcamentoEmEdicao._();

  /// Cria um [OrcamentoEmEdicao] a partir de um mapa JSON.
  factory OrcamentoEmEdicao.fromJson(Map<String, dynamic> json) =>
      _$OrcamentoEmEdicaoFromJson(json);

  /// Se é a edição de um orçamento já salvo.
  bool get ehEdicao => orcamentoOrigemId != null;
}
