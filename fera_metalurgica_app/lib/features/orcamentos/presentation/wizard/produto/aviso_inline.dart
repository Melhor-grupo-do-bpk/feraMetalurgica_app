import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_spacing.dart';
import 'package:fera_metalurgica_app/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Aviso em destaque dentro da etapa 2 (produto não adicionado, medidas a
/// revisar), com uma ação opcional.
class AvisoInline extends StatelessWidget {
  /// Cria o aviso.
  const AvisoInline({required this.texto, this.acao, this.onAcao, super.key});

  /// Mensagem.
  final String texto;

  /// Rótulo do botão; sem ele (ou sem [onAcao]), não há botão.
  final String? acao;

  /// Ação do botão.
  final VoidCallback? onAcao;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final acao = this.acao;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.accentContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                size: 20,
                color: colors.onAccentContainer,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  texto,
                  style: AppTextStyles.body.copyWith(
                    color: colors.onAccentContainer,
                  ),
                ),
              ),
            ],
          ),
          if (acao != null && onAcao != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: colors.onAccentContainer,
                ),
                onPressed: onAcao,
                child: Text(acao),
              ),
            ),
        ],
      ),
    );
  }
}
