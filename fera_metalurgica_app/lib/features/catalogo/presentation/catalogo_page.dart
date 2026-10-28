import 'package:fera_metalurgica_app/core/router/app_routes.dart';
import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_spacing.dart';
import 'package:fera_metalurgica_app/core/theme/app_text_styles.dart';
import 'package:fera_metalurgica_app/core/widgets/app_buttons.dart';
import 'package:fera_metalurgica_app/core/widgets/app_top_bar.dart';
import 'package:fera_metalurgica_app/core/widgets/filter_chips_bar.dart';
import 'package:fera_metalurgica_app/features/catalogo/domain/produto_catalogo.dart';
import 'package:fera_metalurgica_app/features/catalogo/presentation/catalogo_controller.dart';
import 'package:fera_metalurgica_app/features/catalogo/presentation/catalogo_filtro.dart';
import 'package:fera_metalurgica_app/features/catalogo/presentation/produto_card.dart';
import 'package:fera_metalurgica_app/features/catalogo/presentation/produto_detalhes_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Catálogo de produtos, raiz da aba "Catálogo" (Tela 9).
class CatalogoPage extends ConsumerWidget {
  /// Cria a tela.
  const CatalogoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final catalogo = ref.watch(catalogoFiltradoProvider);
    final notifier = ref.read(catalogoCategoriaProvider.notifier);
    final categorias = catalogo.value?.categorias ?? const <String>[];
    final selecionada = catalogo.value?.selecionada;

    return Scaffold(
      appBar: const AppTopBar(),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Catálogo de Produtos',
                    style: AppTextStyles.headline.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Selecione os itens desejados para compor a estrutura do '
                    'seu novo projeto. Todos os materiais seguem rigorosos '
                    'padrões de segurança industrial.',
                    style: AppTextStyles.body.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilterChipsBar(
                    opcoes: ['Todos', ...categorias],
                    selecionado: selecionada == null
                        ? 0
                        : categorias.indexOf(selecionada) + 1,
                    onSelecionado: (i) =>
                        notifier.categoria = i == 0 ? null : categorias[i - 1],
                  ),
                ],
              ),
            ),
          ),
          switch (catalogo) {
            AsyncData(:final value) when value.produtos.isEmpty =>
              const SliverFillRemaining(hasScrollBody: false, child: _Vazio()),
            AsyncData(:final value) => _Lista(produtos: value.produtos),
            AsyncError() => SliverFillRemaining(
              hasScrollBody: false,
              child: _Erro(
                onTentarNovamente: () =>
                    ref.invalidate(produtosCatalogoProvider),
              ),
            ),
            _ => const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            ),
          },
        ],
      ),
    );
  }
}

class _Lista extends StatelessWidget {
  const _Lista({required this.produtos});

  final List<ProdutoCatalogo> produtos;

  Future<void> _abrirDetalhes(
    BuildContext context,
    ProdutoCatalogo produto,
  ) async {
    final usar = await mostrarProdutoDetalhes(context, produto);
    if (usar && context.mounted) {
      await context.push(AppRoutes.novoOrcamento(produtoId: produto.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(AppSpacing.md),
      sliver: SliverList.separated(
        itemCount: produtos.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, i) => ProdutoCard(
          produto: produtos[i],
          onTap: () => _abrirDetalhes(context, produtos[i]),
        ),
      ),
    );
  }
}

class _Vazio extends StatelessWidget {
  const _Vazio();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, size: 48, color: colors.textMuted),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Nenhum produto no catálogo',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _Erro extends StatelessWidget {
  const _Erro({required this.onTentarNovamente});

  final VoidCallback onTentarNovamente;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Não foi possível carregar o catálogo.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedAppButton(
              label: 'Tentar novamente',
              icon: Icons.refresh,
              onPressed: onTentarNovamente,
            ),
          ],
        ),
      ),
    );
  }
}
