import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_spacing.dart';
import 'package:fera_metalurgica_app/core/theme/app_text_styles.dart';
import 'package:fera_metalurgica_app/core/utils/currency_format.dart';
import 'package:fera_metalurgica_app/core/utils/date_format.dart';
import 'package:fera_metalurgica_app/core/widgets/status_chip.dart';
import 'package:fera_metalurgica_app/features/orcamentos/orcamentos.dart';
import 'package:flutter/material.dart';

/// Cartão de um orçamento em "Orçamentos Recentes" (Tela 1, RF-12):
/// número e data, cliente, valor total e chip de status.
class OrcamentoRecenteCard extends StatelessWidget {
  /// Cria o cartão de [orcamento].
  const OrcamentoRecenteCard({
    required this.orcamento,
    required this.onTap,
    super.key,
  });

  /// Orçamento exibido.
  final Orcamento orcamento;

  /// Ação ao tocar no cartão (abrir os detalhes).
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = BorderRadius.circular(AppSpacing.radiusMd);
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: colors.border),
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  text: orcamento.numeroFormatado,
                  style: AppTextStyles.label,
                  children: [
                    TextSpan(
                      text: ' • ${formatarData(orcamento.criadoEm)}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
                style: TextStyle(color: colors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                orcamento.cliente.nome,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body.copyWith(color: colors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Valor Total',
                          style: AppTextStyles.caption.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            formatarMoeda(orcamento.valorFinal),
                            style: AppTextStyles.title.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  StatusChip(
                    label: orcamento.status.label,
                    tone: orcamento.status.tone,
                    showDot: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
