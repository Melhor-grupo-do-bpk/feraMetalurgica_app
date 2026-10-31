import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_spacing.dart';
import 'package:fera_metalurgica_app/core/theme/app_text_styles.dart';
import 'package:fera_metalurgica_app/core/utils/date_format.dart';
import 'package:fera_metalurgica_app/core/widgets/status_chip.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/status_orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/orcamentos_ui.dart';
import 'package:flutter/material.dart';

/// Ações do menu ⋮ do cabeçalho.
enum _AcaoMenu { alternarStatus, excluir }

/// Cabeçalho dos detalhes (Tela 6): o código (com a revisão, D-30), o
/// status (D-29), a data de envio
/// (D-37) e, a partir da 2ª revisão, a data de criação. O menu ⋮ alterna
/// o status e exclui o orçamento; as confirmações ficam com a tela.
class DetalhesStatusCard extends StatelessWidget {
  /// Cria o cabeçalho de [orcamento].
  const DetalhesStatusCard({
    required this.orcamento,
    required this.onAlternarStatus,
    required this.onExcluir,
    super.key,
  });

  /// Orçamento exibido.
  final Orcamento orcamento;

  /// "Marcar como enviado" (de criado) ou "Voltar para criado" (de
  /// enviado).
  final VoidCallback onAlternarStatus;

  /// "Excluir".
  final VoidCallback onExcluir;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final secundario = AppTextStyles.body.copyWith(color: colors.textSecondary);
    final enviadoEm = orcamento.enviadoEm;
    final enviado = orcamento.status == StatusOrcamento.enviado;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.xxs,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        orcamento.codigoExibicao,
                        style: AppTextStyles.title.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    StatusChip(
                      label: orcamento.status.label,
                      tone: orcamento.status.tone,
                      showDot: true,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),
                if (enviado && enviadoEm != null)
                  Text(
                    'Enviado em ${formatarData(enviadoEm)}',
                    style: secundario,
                  )
                else
                  Text('Ainda não enviado', style: secundario),
                if (orcamento.revisao >= 2)
                  Text(
                    'Criado em ${formatarData(orcamento.criadoEm)}',
                    style: secundario,
                  ),
              ],
            ),
          ),
          PopupMenuButton<_AcaoMenu>(
            tooltip: 'Mais opções',
            icon: Icon(Icons.more_vert, color: colors.textSecondary),
            onSelected: (acao) => switch (acao) {
              _AcaoMenu.alternarStatus => onAlternarStatus(),
              _AcaoMenu.excluir => onExcluir(),
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _AcaoMenu.alternarStatus,
                child: Text(
                  enviado ? 'Voltar para criado' : 'Marcar como enviado',
                ),
              ),
              const PopupMenuItem(
                value: _AcaoMenu.excluir,
                child: Text('Excluir'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
