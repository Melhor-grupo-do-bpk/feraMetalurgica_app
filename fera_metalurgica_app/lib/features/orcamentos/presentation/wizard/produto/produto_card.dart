import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_spacing.dart';
import 'package:fera_metalurgica_app/core/theme/app_text_styles.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/item_orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/resultado_item.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/produto/linha_resumo.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/produto/menu_acoes_linha.dart';
import 'package:flutter/material.dart';

/// Produto já no orçamento, na lista da etapa 2: descrição, quantidade,
/// preço base, materiais, preço unitário e total, com o menu de ações. Os
/// valores vêm do [resultado] da `CalculadoraOrcamento`.
class ProdutoCard extends StatelessWidget {
  /// Cria o cartão do produto de posição [numero] (1, 2...).
  const ProdutoCard({
    required this.numero,
    required this.item,
    required this.resultado,
    required this.onAcao,
    super.key,
  });

  /// Posição na lista, a partir de 1.
  final int numero;

  /// O produto.
  final ItemOrcamento item;

  /// O cálculo do produto.
  final ResultadoItem resultado;

  /// Ação do menu; `null` desabilita o menu (com um produto em montagem).
  final ValueChanged<AcaoLinha>? onAcao;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final pecas = item.pecas.length;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.xxs,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Produto ${numero.toString().padLeft(2, '0')}',
                  style: AppTextStyles.label.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
              MenuAcoesLinha(
                tooltip: 'Ações do produto ${item.descricao}',
                onSelecionar: onAcao,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  item.descricao,
                  style: AppTextStyles.bodyStrong.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                LinhaResumo(
                  rotulo: 'Quantidade',
                  valor: '${item.quantidadeProdutos} un',
                ),
                LinhaResumo(
                  rotulo: 'Preço base (sem materiais)',
                  valor: item.precoBase.formatado,
                ),
                LinhaResumo(
                  rotulo: 'Materiais ($pecas ${pecas == 1 ? 'peça' : 'peças'})',
                  valor: resultado.custoMateriais.formatado,
                ),
                LinhaResumo(
                  rotulo: 'Preço unitário',
                  valor: resultado.precoUnitario.formatado,
                ),
                LinhaResumo(
                  rotulo: 'Subtotal do produto',
                  valor: resultado.totalItem.formatado,
                  destaque: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
