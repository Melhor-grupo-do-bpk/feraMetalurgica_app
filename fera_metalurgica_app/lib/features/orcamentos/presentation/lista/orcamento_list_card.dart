import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_spacing.dart';
import 'package:fera_metalurgica_app/core/theme/app_text_styles.dart';
import 'package:fera_metalurgica_app/core/utils/currency_format.dart';
import 'package:fera_metalurgica_app/core/utils/date_format.dart';
import 'package:fera_metalurgica_app/core/widgets/status_chip.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/status_orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/orcamentos_ui.dart';
import 'package:flutter/material.dart';

/// Cartão de um orçamento na lista (Tela 8): número, cliente, status, data
/// e valor final ("Valor Estimado" quando ainda é rascunho, RF-53).
class OrcamentoListCard extends StatelessWidget {
  /// Cria o cartão de [orcamento].
  const OrcamentoListCard({
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
    final rascunho = orcamento.status == StatusOrcamento.rascunho;
    final radius = BorderRadius.circular(AppSpacing.radiusMd);
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: colors.borderSubtle),
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md + AppSpacing.xxs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      orcamento.numeroFormatado,
                      style: AppTextStyles.label.copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                  ),
                  StatusChip(
                    label: orcamento.status.label,
                    tone: orcamento.status.tone,
                  ),
                ],
              ),
              Text(
                orcamento.cliente.nome,
                style: AppTextStyles.title.copyWith(color: colors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Divider(height: 1, color: colors.borderSubtle),
              const SizedBox(height: AppSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: colors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  Text(
                    formatarData(orcamento.criadoEm),
                    style: AppTextStyles.label.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          rascunho ? 'Valor Estimado' : 'Valor Total',
                          style: AppTextStyles.caption.copyWith(
                            color: colors.textMuted,
                          ),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            formatarMoeda(orcamento.valorFinal),
                            style: rascunho
                                ? AppTextStyles.title.copyWith(
                                    fontWeight: FontWeight.w400,
                                    color: colors.textSecondary,
                                  )
                                : AppTextStyles.amount.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: colors.textPrimary,
                                  ),
                          ),
                        ),
                      ],
                    ),
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
