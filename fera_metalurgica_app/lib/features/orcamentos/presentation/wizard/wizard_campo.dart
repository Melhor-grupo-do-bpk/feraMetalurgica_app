import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_spacing.dart';
import 'package:fera_metalurgica_app/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Campo de formulário do wizard: rótulo acima (com `*` vermelho se
/// [obrigatorio]) e o [child] embaixo.
class WizardCampo extends StatelessWidget {
  /// Cria o campo.
  const WizardCampo({
    required this.rotulo,
    required this.child,
    this.obrigatorio = false,
    super.key,
  });

  /// Texto do rótulo.
  final String rotulo;

  /// Se mostra o `*` de campo obrigatório.
  final bool obrigatorio;

  /// O campo em si.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              text: rotulo,
              children: [
                if (obrigatorio)
                  TextSpan(
                    text: ' *',
                    style: TextStyle(color: colors.error),
                  ),
              ],
            ),
            style: AppTextStyles.body.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
          child,
        ],
      ),
    );
  }
}
