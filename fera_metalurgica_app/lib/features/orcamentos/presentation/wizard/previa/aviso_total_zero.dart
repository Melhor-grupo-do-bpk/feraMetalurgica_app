import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_spacing.dart';
import 'package:fera_metalurgica_app/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Destaque do total geral zero (prompt §6): é permitido, mas o operador
/// confere antes de salvar.
class AvisoTotalZero extends StatelessWidget {
  /// Cria o aviso.
  const AvisoTotalZero({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.accentContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 20,
            color: colors.onAccentContainer,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              'O total geral está zerado. Confira os valores antes de '
              'salvar.',
              style: AppTextStyles.body.copyWith(
                color: colors.onAccentContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
