import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_spacing.dart';
import 'package:fera_metalurgica_app/core/theme/app_text_styles.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/item_orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/resultado_item.dart';
import 'package:flutter/material.dart';

/// "Itens do Orçamento" nos detalhes: cada produto com as peças, a
/// quantidade, o preço unitário e o total gravados (D-26). Versão mínima da
/// F2; o acabamento é da V2-D.
class DetalhesItensCard extends StatelessWidget {
  /// Cria o card com [itens] e os [resultados] gravados de cada um.
  const DetalhesItensCard({
    required this.itens,
    required this.resultados,
    super.key,
  });

  /// Produtos do orçamento, na ordem cadastrada.
  final List<ItemOrcamento> itens;

  /// Resultado gravado de cada produto, na mesma ordem de [itens].
  final List<ResultadoItem> resultados;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ColoredBox(
            color: colors.surfaceMuted,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md + AppSpacing.xxs,
                vertical: AppSpacing.sm,
              ),
              child: Text(
                'Itens do Orçamento',
                style: AppTextStyles.title.copyWith(
                  fontWeight: FontWeight.w400,
                  color: colors.textPrimary,
                ),
              ),
            ),
          ),
          for (final (i, item) in itens.indexed) ...[
            Divider(height: 1, color: colors.borderSubtle),
            _ItemLinha(item: item, resultado: resultados[i]),
          ],
        ],
      ),
    );
  }
}

class _ItemLinha extends StatelessWidget {
  const _ItemLinha({required this.item, required this.resultado});

  final ItemOrcamento item;
  final ResultadoItem resultado;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final secundario = AppTextStyles.caption.copyWith(
      color: colors.textSecondary,
    );
    final pecas = item.pecas
        .map((p) => '${p.quantidadePorProduto}× ${p.descricao}')
        .join(' • ');
    final observacoes = item.observacoes?.trim() ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md + AppSpacing.xxs,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.descricao,
            style: AppTextStyles.bodyStrong.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          Text(pecas, style: secundario),
          if (observacoes.isNotEmpty) Text(observacoes, style: secundario),
          Text(
            'Qtd: ${item.quantidadeProdutos} × '
            '${resultado.precoUnitario.formatado} = '
            '${resultado.totalItem.formatado}',
            style: secundario,
          ),
        ],
      ),
    );
  }
}
