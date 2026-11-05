import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_spacing.dart';
import 'package:fera_metalurgica_app/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Aviso em destaque dentro das etapas do wizard e da prévia: documento de
/// outro cadastro (etapa 1), produto não adicionado e medidas a revisar
/// (etapa 2), total zero (etapa 3 e prévia). Fundo `accentContainer`,
/// ícone e texto em `onAccentContainer`, e uma ação opcional à direita.
class AvisoInline extends StatelessWidget {
  /// Cria o aviso.
  const AvisoInline({
    required this.texto,
    this.icone = Icons.info_outline,
    this.acao,
    super.key,
  });

  /// Mensagem.
  final String texto;

  /// Ícone à esquerda do texto.
  final IconData icone;

  /// Botão abaixo do texto, alinhado à direita. Um `TextButton` aqui
  /// recebe a cor `onAccentContainer`, que tem contraste com o fundo.
  final Widget? acao;

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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icone, size: 20, color: colors.onAccentContainer),
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
          if (acao != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: Alignment.centerRight,
              child: TextButtonTheme(
                data: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    foregroundColor: colors.onAccentContainer,
                  ),
                ),
                child: acao,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
