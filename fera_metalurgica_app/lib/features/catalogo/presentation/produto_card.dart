import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_spacing.dart';
import 'package:fera_metalurgica_app/core/theme/app_text_styles.dart';
import 'package:fera_metalurgica_app/features/catalogo/domain/produto_catalogo.dart';
import 'package:fera_metalurgica_app/features/catalogo/presentation/categoria_tag.dart';
import 'package:fera_metalurgica_app/features/catalogo/presentation/produto_foto.dart';
import 'package:flutter/material.dart';

/// Cartão de um produto no catálogo (Tela 9, RF-61): foto 16:9, nome,
/// etiqueta da categoria e descrição técnica.
class ProdutoCard extends StatelessWidget {
  /// Cria o cartão de [produto].
  const ProdutoCard({required this.produto, required this.onTap, super.key});

  /// Produto exibido.
  final ProdutoCatalogo produto;

  /// Ação ao tocar no cartão (abrir os detalhes).
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = BorderRadius.circular(AppSpacing.radiusMd);
    return Material(
      color: colors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: colors.borderSubtle),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ProdutoFoto(fotoPath: produto.fotoPath),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md + AppSpacing.xxs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          produto.nome,
                          style: AppTextStyles.title.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      CategoriaTag(categoria: produto.categoria),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    produto.descricaoTecnica,
                    style: AppTextStyles.body.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
