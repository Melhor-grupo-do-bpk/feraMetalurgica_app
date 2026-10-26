import 'package:fera_metalurgica_app/core/constants/app_constants.dart';
import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_spacing.dart';
import 'package:fera_metalurgica_app/core/theme/app_text_styles.dart';
import 'package:fera_metalurgica_app/core/utils/date_format.dart';
import 'package:fera_metalurgica_app/core/widgets/status_chip.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/status_orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/orcamentos_ui.dart';
import 'package:flutter/material.dart';

/// Status oferecidos em "Alterar status": todos menos `rascunho` (D-06).
const List<StatusOrcamento> _statusDoMenu = [
  StatusOrcamento.emAnalise,
  StatusOrcamento.enviado,
  StatusOrcamento.aprovado,
  StatusOrcamento.recusado,
];

/// Ações do menu ⋮ do card do cliente.
enum _AcaoMenu { alterarStatus }

/// Card do cliente nos detalhes (Tela 6, RF-30): nome, PF/PJ, número,
/// data, prazo e validade, com o menu ⋮ "Alterar status" (RF-33, D-06).
class DetalhesClienteCard extends StatelessWidget {
  /// Cria o card de [orcamento]; [onAlterarStatus] recebe o status
  /// escolhido no menu (só quando difere do atual).
  const DetalhesClienteCard({
    required this.orcamento,
    required this.onAlterarStatus,
    super.key,
  });

  /// Orçamento exibido.
  final Orcamento orcamento;

  /// Chamado com o novo status escolhido em "Alterar status".
  final ValueChanged<StatusOrcamento> onAlterarStatus;

  Future<void> _escolherStatus(BuildContext context) async {
    final novo = await showDialog<StatusOrcamento>(
      context: context,
      builder: (context) => _AlterarStatusDialog(atual: orcamento.status),
    );
    if (novo != null && novo != orcamento.status) onAlterarStatus(novo);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final cliente = orcamento.cliente;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cliente.nome,
                      style: AppTextStyles.headline.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 16,
                          color: colors.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                        Text(
                          cliente.ehPessoaJuridica
                              ? 'Cliente PJ'
                              : 'Cliente PF',
                          style: AppTextStyles.body.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<_AcaoMenu>(
                tooltip: 'Mais opções',
                icon: Icon(Icons.more_vert, color: colors.textSecondary),
                onSelected: (acao) => switch (acao) {
                  _AcaoMenu.alterarStatus => _escolherStatus(context),
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: _AcaoMenu.alterarStatus,
                    child: Text('Alterar status'),
                  ),
                ],
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.md),
                Divider(height: 1, color: colors.borderSubtle),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    _Info(
                      rotulo: 'Orçamento',
                      valor: orcamento.numeroFormatado,
                    ),
                    _Info(
                      rotulo: 'Data',
                      valor: formatarData(orcamento.criadoEm),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    _Info(
                      rotulo: 'Prazo',
                      valor: '${orcamento.prazoDiasUteis} dias úteis',
                    ),
                    const _Info(
                      rotulo: 'Validade',
                      valor: '${AppConstants.validadeOrcamentoDias} dias',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.rotulo, required this.valor});

  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rotulo,
            style: AppTextStyles.caption.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            valor,
            style: AppTextStyles.title.copyWith(
              fontWeight: FontWeight.w400,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AlterarStatusDialog extends StatelessWidget {
  const _AlterarStatusDialog({required this.atual});

  final StatusOrcamento atual;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SimpleDialog(
      title: const Text('Alterar status'),
      children: [
        for (final status in _statusDoMenu)
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(status),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                StatusChip(label: status.label, tone: status.tone),
                const Spacer(),
                if (status == atual)
                  Icon(
                    Icons.check,
                    size: 20,
                    color: colors.brand,
                    semanticLabel: 'Status atual',
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
