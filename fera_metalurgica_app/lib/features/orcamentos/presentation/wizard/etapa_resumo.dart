import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_spacing.dart';
import 'package:fera_metalurgica_app/core/theme/app_text_styles.dart';
import 'package:fera_metalurgica_app/core/utils/currency_format.dart';
import 'package:fera_metalurgica_app/core/widgets/section_card.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/orcamento_wizard_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Etapa 4 do wizard (Tela 5): o resumo como o cliente vai ver (RF-24).
/// Nenhum custo interno aparece aqui, só o valor final (D-16).
class EtapaResumo extends ConsumerWidget {
  /// Cria a etapa ligada ao wizard de [provider].
  const EtapaResumo({required this.provider, super.key});

  /// Provider do wizard aberto.
  final OrcamentoWizardControllerProvider provider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final orcamento = ref.watch(provider).requireValue!.orcamento;
    // O mesmo projeto que o `concluir()` vai gravar (D-02).
    final projeto = orcamento.projeto.isNotEmpty
        ? orcamento.projeto
        : orcamento.itens.firstOrNull?.tipoServico ?? '';
    final secundario = AppTextStyles.caption.copyWith(
      color: colors.textSecondary,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Rotulo(icone: Icons.person_outline, texto: 'Cliente'),
              Text(
                orcamento.cliente.nome,
                style: AppTextStyles.title.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const _Rotulo(
                icone: Icons.architecture_outlined,
                texto: 'Projeto',
              ),
              Text(
                projeto,
                style: AppTextStyles.title.copyWith(color: colors.textPrimary),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SectionCard(
          titulo: 'Itens do pedido',
          icone: Icons.list_alt_outlined,
          child: Column(
            children: [
              for (final (i, item) in orcamento.itens.indexed) ...[
                if (i > 0)
                  Divider(height: AppSpacing.lg, color: colors.borderSubtle),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.tipoServico,
                            style: AppTextStyles.body.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (item.especificacoes != null)
                            Text(item.especificacoes!, style: secundario),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.surfaceVariant,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusXs,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: AppSpacing.xxs,
                        ),
                        child: Text(
                          '${item.quantidade}x',
                          style: AppTextStyles.body.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SectionCard(
          titulo: 'Prazo estimado',
          icone: Icons.calendar_today_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Prazo provisório e só para leitura (D-08).
              Text(
                '${orcamento.prazoDiasUteis} dias úteis',
                style: AppTextStyles.headline.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              Text('Após aprovação e sinal.', style: secundario),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const _Rotulo(
                icone: Icons.payments_outlined,
                texto: 'Valor final',
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  formatarMoeda(orcamento.valorFinal),
                  key: const Key('valor-final'),
                  style: AppTextStyles.display.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const _AvisoVisaoCliente(),
      ],
    );
  }
}

/// Rótulo em caixa alta com ícone ("CLIENTE", "VALOR FINAL").
class _Rotulo extends StatelessWidget {
  const _Rotulo({required this.icone, required this.texto});

  final IconData icone;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 16, color: colors.textSecondary),
          const SizedBox(width: AppSpacing.xs),
          Text(
            texto.toUpperCase(),
            style: AppTextStyles.labelMedium.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvisoVisaoCliente extends StatelessWidget {
  const _AvisoVisaoCliente();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        border: Border(left: BorderSide(color: colors.textPrimary, width: 4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.visibility_outlined, color: colors.textPrimary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Visão do Cliente',
                  style: AppTextStyles.body.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Esta é a visão que será apresentada ao cliente. Custos '
                  'internos de matéria-prima e mão de obra não são exibidos '
                  'no documento final.',
                  style: AppTextStyles.body.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
