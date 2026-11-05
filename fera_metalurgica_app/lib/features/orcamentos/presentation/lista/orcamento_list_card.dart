import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_spacing.dart';
import 'package:fera_metalurgica_app/core/theme/app_text_styles.dart';
import 'package:fera_metalurgica_app/core/utils/date_format.dart';
import 'package:fera_metalurgica_app/core/widgets/status_chip.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/orcamentos_ui.dart';
import 'package:flutter/material.dart';

enum _AcaoCartao { excluir }

/// Cartão de um orçamento na lista (Tela 8): código (com a revisão),
/// cliente, status, data da revisão atual, o total geral gravado (D-30) e o
/// menu com "Excluir".
class OrcamentoListCard extends StatelessWidget {
  /// Cria o cartão de [orcamento].
  const OrcamentoListCard({
    required this.orcamento,
    required this.onTap,
    required this.onExcluir,
    super.key,
  });

  /// Orçamento exibido.
  final Orcamento orcamento;

  /// Ação ao tocar no cartão (abrir os detalhes).
  final VoidCallback onTap;

  /// "Excluir" do menu do cartão.
  final VoidCallback onExcluir;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
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
                      orcamento.codigoExibicao,
                      style: AppTextStyles.label.copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                  ),
                  StatusChip(
                    label: orcamento.status.label,
                    tone: orcamento.status.tone,
                  ),
                  PopupMenuButton<_AcaoCartao>(
                    tooltip: 'Ações do orçamento ${orcamento.codigoExibicao}',
                    icon: Icon(Icons.more_vert, color: colors.textSecondary),
                    onSelected: (_) => onExcluir(),
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: _AcaoCartao.excluir,
                        child: Text('Excluir'),
                      ),
                    ],
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
                  // A data da revisão atual (`atualizadoEm`, HO-V2-F2-04): a
                  // lista é ordenada por ela e a validade conta dela; a
                  // data de criação já está no código (`DDMMAA`).
                  Text(
                    formatarData(orcamento.atualizadoEm),
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
                          'Valor Total',
                          style: AppTextStyles.caption.copyWith(
                            color: colors.textMuted,
                          ),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            orcamento.totalGeral.formatado,
                            style: AppTextStyles.amount.copyWith(
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
