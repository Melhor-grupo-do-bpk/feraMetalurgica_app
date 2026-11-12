import 'package:fera_metalurgica_app/core/di/relogio_provider.dart';
import 'package:fera_metalurgica_app/core/router/app_routes.dart';
import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_spacing.dart';
import 'package:fera_metalurgica_app/core/theme/app_text_styles.dart';
import 'package:fera_metalurgica_app/core/widgets/app_buttons.dart';
import 'package:fera_metalurgica_app/core/widgets/app_top_bar.dart';
import 'package:fera_metalurgica_app/core/widgets/filter_chips_bar.dart';
import 'package:fera_metalurgica_app/core/widgets/section_card.dart';
import 'package:fera_metalurgica_app/features/cronograma/presentation/cronograma/agenda_filtro.dart';
import 'package:fera_metalurgica_app/features/cronograma/presentation/cronograma/agenda_secao.dart';
import 'package:fera_metalurgica_app/features/cronograma/presentation/cronograma/aviso_atrasadas.dart';
import 'package:fera_metalurgica_app/features/cronograma/presentation/cronograma/calendario_mensal.dart';
import 'package:fera_metalurgica_app/features/cronograma/presentation/cronograma/calendario_mes.dart';
import 'package:fera_metalurgica_app/features/cronograma/presentation/cronograma/filtros_tarefas_card.dart';
import 'package:fera_metalurgica_app/features/cronograma/presentation/cronograma/folha_atrasadas.dart';
import 'package:fera_metalurgica_app/features/cronograma/presentation/cronograma_controller.dart';
import 'package:fera_metalurgica_app/features/cronograma/presentation/tarefas_atrasadas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Cronograma e agenda (Tela 10): raiz da aba "Agenda" (D-31).
class CronogramaPage extends ConsumerWidget {
  /// Cria a tela.
  const CronogramaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final hoje = soDia(ref.watch(agoraProvider));
    final filtro = ref.watch(agendaFiltroControllerProvider);
    final controller = ref.read(agendaFiltroControllerProvider.notifier);
    final agenda = ref.watch(agendaProvider);
    final atrasadas = ref.watch(atrasadasProvider).value ?? const [];

    return Scaffold(
      // Raiz da aba "Agenda" (D-31): sem voltar.
      appBar: const AppTopBar(),
      // Acima da barra de navegação translúcida, que fica por cima do
      // conteúdo das abas (D-43).
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
        child: FloatingActionButton(
          onPressed: () => context.push(AppRoutes.tarefa()),
          tooltip: 'Nova tarefa',
          child: const Icon(Icons.add),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          // Espaço para o FAB não cobrir a última tarefa, acima da barra.
          AppSpacing.xl * 3 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          Text(
            'Agenda',
            style: AppTextStyles.headline.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.md),
          if (atrasadas.isNotEmpty) ...[
            AvisoAtrasadas(
              quantidade: atrasadas.length,
              onVer: () async {
                final tarefa = await mostrarFolhaAtrasadas(context, atrasadas);
                if (tarefa != null) controller.selecionarDia(tarefa.data);
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          SectionCard(
            child: CalendarioMensal(
              mesExibido: filtro.mesExibido,
              diaSelecionado: filtro.diaSelecionado,
              diasComPonto: agenda.value?.diasComPendencia ?? const {},
              onDiaSelecionado: controller.selecionarDia,
              onMudarMes: controller.mudarMes,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FiltrosTarefasCard(
            marcados: filtro.tipos,
            onAlterado: controller.marcarTipo,
          ),
          const SizedBox(height: AppSpacing.lg),
          FilterChipsBar(
            opcoes: const ['Por dia', 'Todas'],
            selecionado: filtro.verTodas ? 1 : 0,
            onSelecionado: (i) => controller.mostrarTodas(todas: i == 1),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md + AppSpacing.xxs),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: colors.border),
            ),
            child: switch (agenda) {
              AsyncData(:final value) when value.secoes.isEmpty => Text(
                'Nenhuma tarefa agendada.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(color: colors.textSecondary),
              ),
              AsyncData(:final value) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, secao) in value.secoes.indexed) ...[
                    if (i > 0)
                      Divider(
                        color: colors.borderSubtle,
                        height: AppSpacing.xl,
                      ),
                    AgendaSecao(
                      secao: secao,
                      hoje: hoje,
                      onAlternarConcluida: (t) => ref
                          .read(tarefasProvider.notifier)
                          .alternarConcluida(t.id),
                      onEditar: (t) => context.push(AppRoutes.tarefa(id: t.id)),
                      onVerOrcamento: (id) =>
                          context.push(AppRoutes.detalhesOrcamento(id)),
                    ),
                  ],
                ],
              ),
              AsyncError() => _Erro(
                onTentarNovamente: () => ref.invalidate(tarefasProvider),
              ),
              _ => const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Center(child: CircularProgressIndicator()),
              ),
            },
          ),
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
    return Column(
      children: [
        Text(
          'Não foi possível carregar as tarefas.',
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
    );
  }
}
