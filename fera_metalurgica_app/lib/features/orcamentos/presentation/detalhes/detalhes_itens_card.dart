import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_spacing.dart';
import 'package:fera_metalurgica_app/core/theme/app_text_styles.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/item_orcamento.dart';
import 'package:flutter/material.dart';

/// "Itens do Orçamento" nos detalhes (Tela 6, RF-31): itens descritivos,
/// sem valor por item (D-01).
class DetalhesItensCard extends StatelessWidget {
  /// Cria o card com [itens].
  const DetalhesItensCard({required this.itens, super.key});

  /// Itens do orçamento, na ordem cadastrada.
  final List<ItemOrcamento> itens;

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
          for (final item in itens) ...[
            Divider(height: 1, color: colors.borderSubtle),
            _ItemLinha(item: item),
          ],
        ],
      ),
    );
  }
}

class _ItemLinha extends StatelessWidget {
  const _ItemLinha({required this.item});

  final ItemOrcamento item;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final secundario = AppTextStyles.caption.copyWith(
      color: colors.textSecondary,
    );
    final medidasEMaterial = [
      item.medidas.formatada,
      item.materialPrincipal ?? '',
    ].where((texto) => texto.trim().isNotEmpty).join(' • ');
    final especificacoes = item.especificacoes?.trim() ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md + AppSpacing.xxs,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.tipoServico,
            style: AppTextStyles.bodyStrong.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          if (medidasEMaterial.isNotEmpty)
            Text(medidasEMaterial, style: secundario),
          if (especificacoes.isNotEmpty)
            Text(especificacoes, style: secundario),
          Text('Qtd: ${item.quantidade} un', style: secundario),
        ],
      ),
    );
  }
}
