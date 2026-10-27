import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// Barra de progresso segmentada do wizard de orçamento.
class StepProgressBar extends StatelessWidget {
  /// Cria a barra com [etapaAtual] (1-based) de [totalEtapas] segmentos.
  const StepProgressBar({
    required this.etapaAtual,
    this.totalEtapas = 4,
    super.key,
  }) : assert(
         etapaAtual >= 0 && etapaAtual <= totalEtapas,
         'etapaAtual deve estar entre 0 e totalEtapas',
       );

  /// Etapa atual (1-based). Segmentos até ela ficam preenchidos.
  final int etapaAtual;

  /// Quantidade total de segmentos.
  final int totalEtapas;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      label: 'Etapa $etapaAtual de $totalEtapas',
      child: SizedBox(
        height: 8,
        child: Row(
          // Sem `stretch`, os segmentos (sem filho) ficam com altura 0.
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < totalEtapas; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: DecoratedBox(
                  key: ValueKey('step-segment-$i'),
                  decoration: BoxDecoration(
                    color: i < etapaAtual ? colors.brand : colors.progressTrack,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
