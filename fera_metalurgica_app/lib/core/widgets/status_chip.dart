import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_spacing.dart';
import 'package:fera_metalurgica_app/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Tom visual de um [StatusChip]. O mapeamento de cada status de negócio
/// para um tom fica na feature (o core não conhece os enums das features).
enum StatusTone {
  /// Cinza (ex: "Rascunho", "ORÇAMENTO" no cronograma).
  neutral,

  /// Azul acinzentado (ex: "Em análise", na lista e no dashboard).
  info,

  /// Verde (ex: "Aprovado").
  success,

  /// Vermelho (ex: "Recusado").
  danger,

  /// Laranja de destaque (ex: "PRODUÇÃO").
  accent,
}

/// Badge "pill" de status, com ponto indicador opcional.
class StatusChip extends StatelessWidget {
  /// Cria o chip com o texto [label].
  const StatusChip({
    required this.label,
    this.tone = StatusTone.neutral,
    this.showDot = false,
    this.uppercase = false,
    super.key,
  });

  /// Texto do chip.
  final String label;

  /// Tom de cor.
  final StatusTone tone;

  /// Mostra um ponto antes do texto (estilo do dashboard).
  final bool showDot;

  /// Exibe o texto em caixa alta e negrito (estilo de tag do cronograma).
  final bool uppercase;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (background, foreground) = switch (tone) {
      StatusTone.neutral => (
        colors.neutralContainer,
        colors.onNeutralContainer,
      ),
      StatusTone.info => (colors.infoContainer, colors.onInfoContainer),
      StatusTone.success => (
        colors.successContainer,
        colors.onSuccessContainer,
      ),
      StatusTone.danger => (colors.dangerContainer, colors.onDangerContainer),
      StatusTone.accent => (colors.accentContainer, colors.onAccentContainer),
    };
    final style = uppercase ? AppTextStyles.tag : AppTextStyles.caption;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm - 2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              key: const ValueKey('status-chip-dot'),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: tone == StatusTone.neutral
                    ? colors.neutralDot
                    : foreground,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.xxs),
          ],
          Text(
            uppercase ? label.toUpperCase() : label,
            style: style.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}
