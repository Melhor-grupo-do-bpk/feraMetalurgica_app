import 'package:fera_metalurgica_app/features/orcamentos/domain/orcamento.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'orcamento_wizard_state.freezed.dart';

/// Estado do wizard de orçamento (D-21): a etapa atual e o [Orcamento] em
/// construção. Estado de tela, não é persistido.
@freezed
abstract class OrcamentoWizardState with _$OrcamentoWizardState {
  /// Cria um [OrcamentoWizardState].
  const factory OrcamentoWizardState({
    /// Orçamento em construção. Num orçamento novo, `id` fica vazio até o
    /// `concluir()`.
    required Orcamento orcamento,

    /// Orçamento como estava ao abrir o wizard, para saber se algo mudou.
    required Orcamento inicial,

    /// Se o wizard edita um orçamento já salvo.
    required bool edicao,

    /// Etapa atual, de 1 a 4.
    @Default(1) int etapa,
  }) = _OrcamentoWizardState;

  const OrcamentoWizardState._();

  /// Se o usuário mudou algo desde que abriu o wizard (D-07).
  bool get alterado => orcamento != inicial;
}
