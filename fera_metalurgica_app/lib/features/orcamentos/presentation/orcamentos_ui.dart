import 'package:fera_metalurgica_app/core/widgets/status_chip.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/status_orcamento.dart';

/// Textos e tons de [StatusOrcamento] para a UI.
extension StatusOrcamentoUi on StatusOrcamento {
  /// Rótulo do chip de status (ex: "Em análise").
  String get label => switch (this) {
    StatusOrcamento.rascunho => 'Rascunho',
    StatusOrcamento.emAnalise => 'Em análise',
    StatusOrcamento.enviado => 'Enviado',
    StatusOrcamento.aprovado => 'Aprovado',
    StatusOrcamento.recusado => 'Recusado',
  };

  /// Rótulo do chip de filtro da lista (ex: "Rascunhos"), D-22.
  String get labelFiltro => switch (this) {
    StatusOrcamento.rascunho => 'Rascunhos',
    StatusOrcamento.emAnalise => 'Em análise',
    StatusOrcamento.enviado => 'Enviados',
    StatusOrcamento.aprovado => 'Aprovados',
    StatusOrcamento.recusado => 'Recusados',
  };

  /// Tom do [StatusChip] na lista de orçamentos (Tela 8).
  StatusTone get tone => switch (this) {
    StatusOrcamento.rascunho => StatusTone.neutral,
    StatusOrcamento.emAnalise => StatusTone.info,
    StatusOrcamento.enviado => StatusTone.accent,
    StatusOrcamento.aprovado => StatusTone.success,
    StatusOrcamento.recusado => StatusTone.danger,
  };
}

/// Formatações de [Orcamento] para a UI.
extension OrcamentoUi on Orcamento {
  /// Número exibido nas telas (ex: "#00482"); no PDF use `Nº $id` (D-09).
  String get numeroFormatado => '#$id';
}
