import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_spacing.dart';
import 'package:fera_metalurgica_app/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Card de item adicionado ao orçamento, com ações de editar e excluir.
class ItemCard extends StatelessWidget {
  /// Cria o card.
  const ItemCard({
    required this.rotulo,
    required this.titulo,
    this.detalhes = const [],
    this.rodape,
    this.onEditar,
    this.onExcluir,
    super.key,
  });

  /// Rótulo do item (ex: "Item 01").
  final String rotulo;

  /// Nome do item (ex: "Portão Metálico Basculante").
  final String titulo;

  /// Linhas de detalhe com ícone (ex: medidas, material).
  final List<(IconData, String)> detalhes;

  /// Texto do rodapé (ex: "Qtd: 1 un").
  final String? rodape;

  /// Ação do botão editar; `null` esconde o botão.
  final VoidCallback? onEditar;

  /// Ação do botão excluir; `null` esconde o botão.
  final VoidCallback? onExcluir;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final secundario = AppTextStyles.caption.copyWith(
      color: colors.textSecondary,
    );
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: colors.border),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ColoredBox(
              color: colors.progressTrack,
              child: const SizedBox(width: 4),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md + AppSpacing.xxs,
                  AppSpacing.xs,
                  AppSpacing.xs,
                  AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.grid_view,
                          size: 12,
                          color: colors.textPrimary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            rotulo,
                            style: AppTextStyles.label.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        if (onEditar != null)
                          IconButton(
                            tooltip: 'Editar',
                            iconSize: 16,
                            color: colors.textSecondary,
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: onEditar,
                          ),
                        if (onExcluir != null)
                          IconButton(
                            tooltip: 'Excluir',
                            iconSize: 16,
                            color: colors.textSecondary,
                            icon: const Icon(Icons.delete_outline),
                            onPressed: onExcluir,
                          ),
                      ],
                    ),
                    Text(
                      titulo,
                      style: AppTextStyles.body.copyWith(color: colors.brand),
                    ),
                    for (final (icone, texto) in detalhes)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xxs),
                        child: Row(
                          children: [
                            Icon(icone, size: 12, color: colors.textSecondary),
                            const SizedBox(width: AppSpacing.xxs),
                            Flexible(child: Text(texto, style: secundario)),
                          ],
                        ),
                      ),
                    if (rodape != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Divider(color: colors.surfaceVariant),
                      const SizedBox(height: AppSpacing.xs),
                      Text(rodape!, style: secundario),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
