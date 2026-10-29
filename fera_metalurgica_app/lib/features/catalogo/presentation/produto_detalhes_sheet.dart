import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_spacing.dart';
import 'package:fera_metalurgica_app/core/theme/app_text_styles.dart';
import 'package:fera_metalurgica_app/core/widgets/app_buttons.dart';
import 'package:fera_metalurgica_app/features/catalogo/domain/produto_catalogo.dart';
import 'package:fera_metalurgica_app/features/catalogo/presentation/categoria_tag.dart';
import 'package:fera_metalurgica_app/features/catalogo/presentation/produto_foto.dart';
import 'package:flutter/material.dart';

/// Abre a folha de detalhes de [produto] (RF-62). Devolve `true` se o
/// usuário tocou em "Usar no orçamento"; quem abriu faz a navegação.
Future<bool> mostrarProdutoDetalhes(
  BuildContext context,
  ProdutoCatalogo produto,
) async {
  final usar = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => ProdutoDetalhesSheet(produto: produto),
  );
  return usar ?? false;
}

/// Conteúdo da folha de detalhes: foto, nome, categoria, descrição técnica
/// e o botão "Usar no orçamento", que fecha a folha devolvendo `true`.
class ProdutoDetalhesSheet extends StatelessWidget {
  /// Cria a folha de [produto].
  const ProdutoDetalhesSheet({required this.produto, super.key});

  /// Produto exibido.
  final ProdutoCatalogo produto;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: ProdutoFoto(fotoPath: produto.fotoPath),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            produto.nome,
            style: AppTextStyles.headline.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.xs),
          CategoriaTag(categoria: produto.categoria),
          const SizedBox(height: AppSpacing.md),
          Text(
            produto.descricaoTecnica,
            style: AppTextStyles.body.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: 'Usar no orçamento',
            icon: Icons.add,
            large: true,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
  }
}
