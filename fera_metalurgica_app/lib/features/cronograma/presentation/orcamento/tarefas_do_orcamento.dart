import 'package:fera_metalurgica_app/core/router/app_routes.dart';
import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_spacing.dart';
import 'package:fera_metalurgica_app/core/theme/app_text_styles.dart';
import 'package:fera_metalurgica_app/core/utils/date_format.dart';
import 'package:fera_metalurgica_app/core/widgets/app_buttons.dart';
import 'package:fera_metalurgica_app/core/widgets/status_chip.dart';
import 'package:fera_metalurgica_app/features/cronograma/domain/tarefa.dart';
import 'package:fera_metalurgica_app/features/cronograma/presentation/cronograma_controller.dart';
import 'package:fera_metalurgica_app/features/cronograma/presentation/cronograma_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Tarefas vinculadas ao orçamento [orcamentoId], para os detalhes do
/// orçamento (v2-plano §6, item 4). A V2-D posiciona, dentro da seção
/// "Agenda" dela; a V2-E implementa.
///
/// Pendentes primeiro, depois as concluídas, cada grupo em ordem
/// cronológica. Tocar na tarefa abre a edição; o marcador a conclui (ou a
/// volta para pendente). Sem título próprio, sem rolagem e sem `Expanded`
/// na vertical: fica dentro da rolagem da página de detalhes.
class TarefasDoOrcamento extends ConsumerWidget {
  /// Cria a lista das tarefas de [orcamentoId].
  const TarefasDoOrcamento({required this.orcamentoId, super.key});

  /// Id do orçamento cujas tarefas são mostradas.
  final String orcamentoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final mensagem = AppTextStyles.body.copyWith(color: colors.textSecondary);

    return switch (ref.watch(tarefasDoOrcamentoProvider(orcamentoId))) {
      AsyncData(value: []) => Text('Nenhuma tarefa agendada.', style: mensagem),
      AsyncData(:final value) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, tarefa) in _pendentesPrimeiro(value).indexed) ...[
            if (i > 0) Divider(height: 1, color: colors.borderSubtle),
            _LinhaTarefa(
              key: ValueKey('tarefa-orcamento-${tarefa.id}'),
              tarefa: tarefa,
              onTap: () => context.push(AppRoutes.tarefa(id: tarefa.id)),
              onAlternarConcluida: () => ref
                  .read(tarefasProvider.notifier)
                  .alternarConcluida(tarefa.id),
            ),
          ],
        ],
      ),
      AsyncError() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Não foi possível carregar as tarefas.', style: mensagem),
          const SizedBox(height: AppSpacing.sm),
          OutlinedAppButton(
            label: 'Tentar novamente',
            icon: Icons.refresh,
            onPressed: () => ref.invalidate(tarefasProvider),
          ),
        ],
      ),
      _ => const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Center(child: CircularProgressIndicator()),
      ),
    };
  }
}

/// [tarefas] com as pendentes primeiro e as concluídas depois, mantendo a
/// ordem de cada grupo.
List<Tarefa> _pendentesPrimeiro(List<Tarefa> tarefas) => [
  for (final t in tarefas)
    if (!t.concluida) t,
  for (final t in tarefas)
    if (t.concluida) t,
];

class _LinhaTarefa extends StatelessWidget {
  const _LinhaTarefa({
    required this.tarefa,
    required this.onTap,
    required this.onAlternarConcluida,
    super.key,
  });

  final Tarefa tarefa;
  final VoidCallback onTap;
  final VoidCallback onAlternarConcluida;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final concluida = tarefa.concluida;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            IconButton(
              key: const ValueKey('tarefa-orcamento-marcador'),
              onPressed: onAlternarConcluida,
              tooltip: concluida
                  ? 'Marcar como pendente'
                  : 'Marcar como concluída',
              icon: Icon(
                concluida ? Icons.check_circle : Icons.radio_button_unchecked,
                color: concluida
                    ? colors.textMuted
                    : tarefa.tipo.corDestaque(colors),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tarefa.titulo,
                    style:
                        (concluida
                                ? AppTextStyles.body
                                : AppTextStyles.bodyStrong)
                            .copyWith(
                              color: concluida
                                  ? colors.textSecondary
                                  : colors.textPrimary,
                              decoration: concluida
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    '${formatarData(tarefa.data)} • '
                    '${formatarHora(tarefa.data)}',
                    style: AppTextStyles.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (!concluida) ...[
              const SizedBox(width: AppSpacing.sm),
              StatusChip(
                label: tarefa.tipo.label,
                tone: tarefa.tipo.tone,
                uppercase: true,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
