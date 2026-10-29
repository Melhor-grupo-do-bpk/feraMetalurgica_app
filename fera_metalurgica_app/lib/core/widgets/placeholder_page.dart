import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_spacing.dart';
import 'package:fera_metalurgica_app/core/theme/app_text_styles.dart';
import 'package:fera_metalurgica_app/core/widgets/app_top_bar.dart';
import 'package:flutter/material.dart';

/// Tela provisória das telas cujas features ainda não foram implementadas.
class PlaceholderPage extends StatelessWidget {
  /// Cria a tela com o [titulo] da aba. [onBack] mostra o botão voltar na
  /// top bar (telas abertas por cima de uma aba).
  const PlaceholderPage({required this.titulo, this.onBack, super.key});

  /// Título exibido no centro da tela.
  final String titulo;

  /// Ação do botão voltar; sem ele, o botão não aparece.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      appBar: AppTopBar(onBack: onBack),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                titulo,
                style: AppTextStyles.headline.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Em construção',
                style: AppTextStyles.label.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
