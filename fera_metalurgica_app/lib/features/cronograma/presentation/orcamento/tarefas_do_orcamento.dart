import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_text_styles.dart';
import 'package:fera_metalurgica_app/core/utils/date_format.dart';
import 'package:fera_metalurgica_app/features/cronograma/presentation/cronograma_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tarefas vinculadas ao orçamento [orcamentoId], para os detalhes do
/// orçamento (v2-plano §6, item 4). A V2-D posiciona; a V2-E implementa.
///
/// Stub da F2: título e data de cada tarefa, em ordem cronológica.
// TODO(V2-E): pendentes primeiro, abrir a tarefa e marcar como concluída.
class TarefasDoOrcamento extends ConsumerWidget {
  /// Cria a lista das tarefas de [orcamentoId].
  const TarefasDoOrcamento({required this.orcamentoId, super.key});

  /// Id do orçamento cujas tarefas são mostradas.
  final String orcamentoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final tarefas = ref.watch(tarefasDoOrcamentoProvider(orcamentoId)).value;
    if (tarefas == null || tarefas.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final tarefa in tarefas)
          Text(
            '${formatarData(tarefa.data)} ${formatarHora(tarefa.data)} • '
            '${tarefa.titulo}',
            style: AppTextStyles.body.copyWith(color: colors.textPrimary),
          ),
      ],
    );
  }
}
