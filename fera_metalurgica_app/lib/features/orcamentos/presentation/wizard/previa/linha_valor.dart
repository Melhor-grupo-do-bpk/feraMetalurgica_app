import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_spacing.dart';
import 'package:fera_metalurgica_app/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Linha "rótulo ... valor" dos totais da prévia e da etapa 3. O rótulo
/// quebra em várias linhas se precisar; o valor nunca quebra.
class LinhaValor extends StatelessWidget {
  /// Cria a linha com [rotulo] e [valor] (já formatado).
  const LinhaValor({
    required this.rotulo,
    required this.valor,
    this.destaque = false,
    super.key,
  });

  /// Texto da esquerda.
  final String rotulo;

  /// Texto da direita, já formatado (ex: `R$ 1.234,56`).
  final String valor;

  /// Linha do total geral: texto maior e em negrito.
  final bool destaque;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final estilo = destaque
        ? AppTextStyles.title.copyWith(color: colors.textPrimary)
        : AppTextStyles.body.copyWith(color: colors.textSecondary);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(rotulo, style: estilo)),
          const SizedBox(width: AppSpacing.sm),
          Text(
            valor,
            style: estilo.copyWith(
              color: colors.textPrimary,
              fontWeight: destaque ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
