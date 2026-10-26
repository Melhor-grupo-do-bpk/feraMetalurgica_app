import 'package:fera_metalurgica_app/core/router/app_routes.dart';
import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_spacing.dart';
import 'package:fera_metalurgica_app/core/theme/app_text_styles.dart';
import 'package:fera_metalurgica_app/core/widgets/app_buttons.dart';
import 'package:fera_metalurgica_app/core/widgets/app_top_bar.dart';
import 'package:fera_metalurgica_app/core/widgets/filter_chips_bar.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/status_orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/lista/orcamento_list_card.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/lista/orcamentos_lista_filtro.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/orcamentos_controller.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/orcamentos_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Chips de filtro na ordem de D-22; `null` é "Todos".
const List<StatusOrcamento?> _filtros = [null, ...StatusOrcamento.values];

/// Lista de orçamentos, raiz da aba "Orçamentos" (Tela 8).
class OrcamentosListaPage extends ConsumerWidget {
  /// Cria a tela.
  const OrcamentosListaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final filtro = ref.watch(orcamentosListaFiltroProvider);
    final notifier = ref.read(orcamentosListaFiltroProvider.notifier);
    final orcamentos = ref.watch(orcamentosListaFiltradosProvider);

    return Scaffold(
      appBar: const AppTopBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Orçamentos',
                        style: AppTextStyles.headline.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    const _BotaoNovo(),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  onChanged: notifier.buscar,
                  textInputAction: TextInputAction.search,
                  decoration: const InputDecoration(
                    hintText: 'Buscar por cliente ou número...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                FilterChipsBar(
                  opcoes: [
                    for (final status in _filtros)
                      status?.labelFiltro ?? 'Todos',
                  ],
                  selecionado: _filtros.indexOf(filtro.status),
                  onSelecionado: (i) => notifier.filtrarPorStatus(_filtros[i]),
                ),
              ],
            ),
          ),
          Expanded(
            child: switch (orcamentos) {
              AsyncData(:final value) when value.isEmpty => const _Vazio(),
              AsyncData(:final value) => _Lista(orcamentos: value),
              AsyncError() => _Erro(
                onTentarNovamente: () => ref.invalidate(orcamentosProvider),
              ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ],
      ),
    );
  }
}

class _BotaoNovo extends StatelessWidget {
  const _BotaoNovo();

  @override
  Widget build(BuildContext context) => DarkButton(
    label: 'Novo',
    icon: Icons.add,
    onPressed: () => context.push(AppRoutes.novoOrcamento()),
  );
}

class _Lista extends StatelessWidget {
  const _Lista({required this.orcamentos});

  final List<Orcamento> orcamentos;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: orcamentos.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, i) {
        final orcamento = orcamentos[i];
        return OrcamentoListCard(
          orcamento: orcamento,
          onTap: () => context.push(AppRoutes.detalhesOrcamento(orcamento.id)),
        );
      },
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
            Icon(Icons.description_outlined, size: 48, color: colors.textMuted),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Nenhum orçamento encontrado',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            const _BotaoNovo(),
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
              'Não foi possível carregar os orçamentos.',
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
