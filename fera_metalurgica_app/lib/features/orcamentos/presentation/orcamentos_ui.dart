import 'package:fera_metalurgica_app/core/widgets/status_chip.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/status_orcamento.dart';

/// Textos e tons de [StatusOrcamento] para a UI (D-29).
extension StatusOrcamentoUi on StatusOrcamento {
  /// Rótulo do chip de status (ex: "Criado").
  String get label => switch (this) {
    StatusOrcamento.criado => 'Criado',
    StatusOrcamento.enviado => 'Enviado',
  };

  /// Rótulo do chip de filtro da lista (ex: "Criados"), D-29.
  String get labelFiltro => switch (this) {
    StatusOrcamento.criado => 'Criados',
    StatusOrcamento.enviado => 'Enviados',
  };

  /// Tom do [StatusChip] na lista de orçamentos.
  StatusTone get tone => switch (this) {
    StatusOrcamento.criado => StatusTone.info,
    StatusOrcamento.enviado => StatusTone.accent,
  };
}
