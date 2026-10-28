import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_spacing.dart';
import 'package:fera_metalurgica_app/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Etiqueta retangular com a categoria do produto, como na Tela 9.
///
/// Diferente do `StatusChip` (pílula sem borda). Uso interno da feature,
/// fora do barrel.
// TODO(T8): unificar com o `StatusChip` em `core/widgets/` se fizer sentido.
class CategoriaTag extends StatelessWidget {
  /// Cria a etiqueta com [categoria].
  const CategoriaTag({required this.categoria, super.key});

  /// Nome da categoria.
  final String categoria;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
        border: Border.all(color: colors.border),
      ),
      child: Text(
        categoria,
        style: AppTextStyles.caption.copyWith(color: colors.textSecondary),
      ),
    );
  }
}
