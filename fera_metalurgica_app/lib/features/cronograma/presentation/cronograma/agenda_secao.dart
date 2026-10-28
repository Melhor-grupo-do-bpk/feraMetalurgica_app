import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_spacing.dart';
import 'package:fera_metalurgica_app/core/theme/app_text_styles.dart';
import 'package:fera_metalurgica_app/core/utils/date_format.dart';
import 'package:fera_metalurgica_app/core/widgets/status_chip.dart';
import 'package:fera_metalurgica_app/core/widgets/timeline_tile.dart';
import 'package:fera_metalurgica_app/features/cronograma/domain/tarefa.dart';
import 'package:fera_metalurgica_app/features/cronograma/presentation/cronograma/agenda_filtro.dart';
import 'package:fera_metalurgica_app/features/cronograma/presentation/cronograma_ui.dart';
import 'package:flutter/material.dart';

/// Uma seção da linha do tempo (RF-83): "Hoje" + "N tarefas" e as
/// tarefas do dia em [TimelineTile].
class AgendaSecao extends StatelessWidget {
  /// Cria a seção.
  const AgendaSecao({
    required this.secao,
    required this.hoje,
    required this.onAlternarConcluida,
    required this.onEditar,
    required this.onVerOrcamento,
    super.key,
  });

  /// Dia e tarefas visíveis.
  final SecaoAgenda secao;

  /// "Hoje", para o título "Hoje"/"Amanhã".
  final DateTime hoje;

  /// Toque no marcador da tarefa (RF-84).
  final ValueChanged<Tarefa> onAlternarConcluida;

  /// Tocar e segurar a tarefa (RF-86).
  final ValueChanged<Tarefa> onEditar;

  /// "Ver Detalhes" da tarefa com `orcamentoId` (RF-85).
  final ValueChanged<String> onVerOrcamento;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tarefas = secao.tarefas;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                rotuloDia(secao.dia, hoje),
                style: AppTextStyles.headline.copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            StatusChip(label: contarTarefas(tarefas.length)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (tarefas.isEmpty)
          Text(
            'Nenhuma tarefa neste dia',
            style: AppTextStyles.body.copyWith(color: colors.textSecondary),
          )
        else
          for (final (i, tarefa) in tarefas.indexed)
            GestureDetector(
              key: ValueKey('tarefa-${tarefa.id}'),
              behavior: HitTestBehavior.opaque,
              onLongPress: () => onEditar(tarefa),
              child: TimelineTile(
                horario: formatarHora(tarefa.data),
                titulo: tarefa.titulo,
                descricao: tarefa.descricao,
                tag: StatusChip(
                  label: tarefa.tipo.label,
                  tone: tarefa.tipo.tone,
                  uppercase: true,
                ),
                acao: tarefa.orcamentoId == null
                    ? null
                    : _VerDetalhes(
                        onPressed: () => onVerOrcamento(tarefa.orcamentoId!),
                      ),
                corDestaque: tarefa.tipo.corDestaque(colors),
                concluida: tarefa.concluida,
                ultimo: i == tarefas.length - 1,
                onMarcadorPressed: () => onAlternarConcluida(tarefa),
              ),
            ),
      ],
    );
  }
}

class _VerDetalhes extends StatelessWidget {
  const _VerDetalhes({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return TextButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.visibility_outlined, size: 18),
      label: const Text('Ver Detalhes'),
      style: TextButton.styleFrom(
        foregroundColor: colors.textPrimary,
        textStyle: AppTextStyles.labelStrong,
        padding: EdgeInsets.zero,
        alignment: Alignment.centerLeft,
      ),
    );
  }
}
