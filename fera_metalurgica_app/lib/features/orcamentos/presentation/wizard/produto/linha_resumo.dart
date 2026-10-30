import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_spacing.dart';
import 'package:fera_metalurgica_app/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Linha "rótulo ... valor" dos resumos da peça e do produto. O valor vem
/// sempre da `CalculadoraOrcamento`, já formatado.
class LinhaResumo extends StatelessWidget {
  /// Cria a linha.
  const LinhaResumo({
    required this.rotulo,
    required this.valor,
    this.destaque = false,
    super.key,
  });

  /// Texto à esquerda.
  final String rotulo;

  /// Valor à direita.
  final String valor;

  /// Se a linha é um total (texto forte).
  final bool destaque;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final estilo = destaque
        ? AppTextStyles.bodyStrong.copyWith(color: colors.textPrimary)
        : AppTextStyles.body.copyWith(color: colors.textSecondary);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(rotulo, style: estilo)),
          const SizedBox(width: AppSpacing.xs),
          Text(valor, style: estilo, textAlign: TextAlign.right),
        ],
      ),
    );
  }
}
