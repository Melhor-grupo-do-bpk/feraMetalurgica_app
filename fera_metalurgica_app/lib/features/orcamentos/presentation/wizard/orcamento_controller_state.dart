import 'package:fera_metalurgica_app/core/domain/erro_validacao.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/v2/orcamento_em_edicao.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/v2/resultado_orcamento.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'orcamento_controller_state.freezed.dart';

/// Estado do `OrcamentoController` (D-28): a sessão de edição e o que as
/// telas do wizard mostram. Estado de tela, não é persistido.
@freezed
abstract class EstadoEdicaoOrcamento with _$EstadoEdicaoOrcamento {
  /// Cria um [EstadoEdicaoOrcamento].
  const factory EstadoEdicaoOrcamento({
    /// Sessão em edição; `null` antes de `iniciar`/`iniciarEdicao` e depois
    /// de `finalizar` ou `descartar`.
    OrcamentoEmEdicao? edicao,

    /// Etapa atual, de 1 a [totalEtapas]. Voltar é sempre permitido.
    @Default(1) int etapaAtual,

    /// Totais calculados a partir dos itens e valores da sessão, só quando
    /// eles estão válidos (senão `null`).
    ResultadoOrcamento? resumo,

    /// Erros da última operação (avançar, adicionar, finalizar...).
    @Default(<ErroValidacao>[]) List<ErroValidacao> erros,

    /// Se a gravação está em andamento: bloqueia o clique repetido e as
    /// alterações.
    @Default(false) bool finalizando,
  }) = _EstadoEdicaoOrcamento;

  const EstadoEdicaoOrcamento._();

  /// Quantas etapas o wizard tem: cliente, produtos, valores e prévia.
  static const int totalEtapas = 4;

  /// Se a sessão é a edição de um orçamento salvo (D-30).
  bool get ehEdicao => edicao?.ehEdicao ?? false;
}
