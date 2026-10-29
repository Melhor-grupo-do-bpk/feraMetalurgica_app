import 'package:fera_metalurgica_app/core/router/app_routes.dart';
import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_spacing.dart';
import 'package:fera_metalurgica_app/core/theme/app_text_styles.dart';
import 'package:fera_metalurgica_app/core/widgets/app_buttons.dart';
import 'package:fera_metalurgica_app/core/widgets/app_top_bar.dart';
import 'package:fera_metalurgica_app/core/widgets/stat_card.dart';
import 'package:fera_metalurgica_app/features/cronograma/cronograma.dart';
import 'package:fera_metalurgica_app/features/dashboard/presentation/dashboard_indicadores.dart';
import 'package:fera_metalurgica_app/features/dashboard/presentation/orcamento_recente_card.dart';
import 'package:fera_metalurgica_app/features/orcamentos/orcamentos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Tela inicial do app, raiz da aba "Início" (Tela 1): botão "Criar
/// orçamento", os 4 indicadores (D-03) e os orçamentos recentes (RF-12).
class DashboardPage extends ConsumerWidget {
  /// Cria a tela inicial do dashboard.
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final indicadores = ref.watch(indicadoresDashboardProvider);
    final recentes = ref.watch(recentesDashboardProvider);

    return Scaffold(
      appBar: const AppTopBar(),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          PrimaryButton(
            label: 'Criar orçamento',
            icon: Icons.add,
            large: true,
            onPressed: () => context.push(AppRoutes.novoOrcamento()),
          ),
          const SizedBox(height: AppSpacing.lg),
          switch ((indicadores, recentes)) {
            (AsyncData(value: final i), AsyncData(value: final r)) => _Conteudo(
              indicadores: i,
              recentes: r,
            ),
            (AsyncError(), _) || (_, AsyncError()) => _Erro(
              onTentarNovamente: () => ref
                ..invalidate(orcamentosProvider)
                ..invalidate(tarefasProvider),
            ),
            _ => const Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Center(child: CircularProgressIndicator()),
            ),
          },
        ],
      ),
    );
  }
}

class _Conteudo extends StatelessWidget {
  const _Conteudo({required this.indicadores, required this.recentes});

  final IndicadoresDashboard indicadores;
  final List<Orcamento> recentes;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _LinhaDeCards(
          esquerda: StatCard(
            label: 'Orçamentos em andamento',
            valor: formatarContagem(indicadores.emAndamento),
            icone: Icons.pending_actions,
          ),
          direita: StatCard(
            label: 'Aguardando aprovação',
            valor: formatarContagem(indicadores.aguardandoAprovacao),
            icone: Icons.hourglass_empty,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _LinhaDeCards(
          esquerda: StatCard(
            label: 'Aprovados',
            valor: formatarContagem(indicadores.aprovados),
            icone: Icons.check_circle_outline,
          ),
          direita: StatCard(
            label: 'Pedidos em produção',
            valor: formatarContagem(indicadores.pedidosEmProducao),
            icone: Icons.factory_outlined,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            Expanded(
              child: Text(
                'Orçamentos Recentes',
                style: AppTextStyles.headline.copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ),
            TextButton(
              onPressed: () => context.go(AppRoutes.orcamentos),
              style: TextButton.styleFrom(
                foregroundColor: colors.textSecondary,
                textStyle: AppTextStyles.label,
              ),
              child: const Text('Ver todos'),
            ),
          ],
        ),
        Divider(height: AppSpacing.md, color: colors.border),
        const SizedBox(height: AppSpacing.xs),
        if (recentes.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Text(
              'Nenhum orçamento ainda.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: colors.textSecondary),
            ),
          )
        else
          for (final orcamento in recentes) ...[
            OrcamentoRecenteCard(
              orcamento: orcamento,
              onTap: () =>
                  context.push(AppRoutes.detalhesOrcamento(orcamento.id)),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
      ],
    );
  }
}

/// Dois [StatCard] lado a lado, com a mesma altura.
class _LinhaDeCards extends StatelessWidget {
  const _LinhaDeCards({required this.esquerda, required this.direita});

  final Widget esquerda;
  final Widget direita;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: esquerda),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: direita),
        ],
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
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Text(
            'Não foi possível carregar o painel.',
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
    );
  }
}
