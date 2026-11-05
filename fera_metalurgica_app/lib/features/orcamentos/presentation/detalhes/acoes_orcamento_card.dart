import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// Card escuro com as ações dos detalhes (Tela 6, RF-32 a RF-34): Enviar
/// WhatsApp, Gerar PDF e Editar.
///
/// Não repete o total: o total geral fica só no card "Totais" da prévia
/// (D-39), logo acima.
class AcoesOrcamentoCard extends StatelessWidget {
  /// Cria o card com as três ações.
  const AcoesOrcamentoCard({
    required this.onEnviarWhatsApp,
    required this.onGerarPdf,
    required this.onEditar,
    super.key,
  });

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
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.brand,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
