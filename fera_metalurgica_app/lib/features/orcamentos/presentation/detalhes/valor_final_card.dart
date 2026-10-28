import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_spacing.dart';
import 'package:fera_metalurgica_app/core/theme/app_text_styles.dart';
import 'package:fera_metalurgica_app/core/utils/currency_format.dart';
import 'package:flutter/material.dart';

/// Card escuro "Valor Final" dos detalhes (Tela 6, RF-32), com as ações
/// Enviar WhatsApp, Gerar PDF e Editar.
///
/// Só mostra o valor final; custos internos nunca aparecem aqui (D-16).
class ValorFinalCard extends StatelessWidget {
  /// Cria o card com [valorFinal] e as três ações.
  const ValorFinalCard({
    required this.valorFinal,
    required this.onEnviarWhatsApp,
    required this.onGerarPdf,
    required this.onEditar,
    super.key,
  });

  /// Valor final do orçamento (`Orcamento.valorFinal`).
  final double valorFinal;

  /// Ação do botão "Enviar WhatsApp".
  final VoidCallback onEnviarWhatsApp;

  /// Ação do botão "Gerar PDF".
  final VoidCallback onGerarPdf;

  /// Ação do botão "Editar".
  final VoidCallback onEditar;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    const tamanhoBotao = Size.fromHeight(48);
    final formatoBotao = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg + AppSpacing.xs),
      decoration: BoxDecoration(
        color: colors.brand,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Valor Final',
            style: AppTextStyles.title.copyWith(
              fontWeight: FontWeight.w400,
              color: colors.onBrand.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatarMoeda(valorFinal),
              style: AppTextStyles.display.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.onBrand,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg + AppSpacing.xs),
          FilledButton.icon(
            onPressed: onEnviarWhatsApp,
            icon: const Icon(Icons.chat_outlined, size: 20),
            label: const Text('Enviar WhatsApp'),
            style: FilledButton.styleFrom(
              minimumSize: tamanhoBotao,
              shape: formatoBotao,
              backgroundColor: colors.whatsapp,
              foregroundColor: colors.onWhatsapp,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: onGerarPdf,
            icon: const Icon(Icons.picture_as_pdf_outlined, size: 20),
            label: const Text('Gerar PDF'),
            style: FilledButton.styleFrom(
              minimumSize: tamanhoBotao,
              shape: formatoBotao,
              backgroundColor: colors.neutralContainer,
              foregroundColor: colors.onNeutralContainer,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: onEditar,
            icon: const Icon(Icons.edit_outlined, size: 20),
            label: const Text('Editar'),
            style: OutlinedButton.styleFrom(
              minimumSize: tamanhoBotao,
              shape: formatoBotao,
              foregroundColor: colors.onBrand,
              side: BorderSide(color: colors.onBrand.withValues(alpha: 0.6)),
            ),
          ),
        ],
      ),
    );
  }
}
