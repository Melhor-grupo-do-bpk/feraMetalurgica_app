import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/widgets/status_chip.dart';
import 'package:fera_metalurgica_app/features/cronograma/domain/tipo_tarefa.dart';
import 'package:flutter/material.dart';

/// Textos e cores de [TipoTarefa] para a UI.
extension TipoTarefaUi on TipoTarefa {
  /// Rótulo da tag da tarefa (ex: "Orçamento"; exibida em caixa alta).
  String get label => switch (this) {
    TipoTarefa.orcamento => 'Orçamento',
    TipoTarefa.producao => 'Produção',
    TipoTarefa.visita => 'Visita',
  };

  /// Rótulo do filtro de tarefas (ex: "Orçamentos"), D-05.
  String get labelFiltro => switch (this) {
    TipoTarefa.orcamento => 'Orçamentos',
    TipoTarefa.producao => 'Produção',
    TipoTarefa.visita => 'Visitas',
  };

  /// Tom da tag ([StatusChip] com `uppercase: true`).
  StatusTone get tone => switch (this) {
    TipoTarefa.orcamento => StatusTone.neutral,
    TipoTarefa.producao => StatusTone.accent,
    TipoTarefa.visita => StatusTone.info,
  };

  /// Cor do marcador e da faixa lateral do `TimelineTile`.
  Color corDestaque(AppColors colors) => switch (this) {
    TipoTarefa.orcamento => colors.darkSurface,
    TipoTarefa.producao => colors.accent,
    TipoTarefa.visita => colors.onInfoContainer,
  };
}
