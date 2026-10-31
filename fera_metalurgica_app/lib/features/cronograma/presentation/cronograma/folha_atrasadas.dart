import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_spacing.dart';
import 'package:fera_metalurgica_app/core/theme/app_text_styles.dart';
import 'package:fera_metalurgica_app/core/utils/date_format.dart';
import 'package:fera_metalurgica_app/core/widgets/status_chip.dart';
import 'package:fera_metalurgica_app/features/cronograma/domain/tarefa.dart';
import 'package:fera_metalurgica_app/features/cronograma/presentation/cronograma_ui.dart';
import 'package:fera_metalurgica_app/features/cronograma/presentation/tarefas_atrasadas.dart';
import 'package:flutter/material.dart';

/// Abre a lista das tarefas [atrasadas] (v2-plano §6, item 7) e devolve a
/// tocada, ou `null` se o operador fechar a folha. Folha, não tela: não tem
/// rota (`03-padroes.md` §3).
Future<Tarefa?> mostrarFolhaAtrasadas(
  BuildContext context,
  List<Tarefa> atrasadas,
) => showModalBottomSheet<Tarefa>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (context) => FolhaAtrasadas(atrasadas: atrasadas),
);

/// Conteúdo da folha das tarefas atrasadas: título com a contagem e as
/// tarefas, da mais antiga para a mais nova. Tocar numa delas fecha a folha
/// devolvendo a tarefa.
class FolhaAtrasadas extends StatelessWidget {
  /// Cria a folha com as tarefas [atrasadas].
  const FolhaAtrasadas({required this.atrasadas, super.key});

  /// Tarefas atrasadas, em ordem cronológica.
  final List<Tarefa> atrasadas;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Text(
              contarAtrasadas(atrasadas.length),
              style: AppTextStyles.headline.copyWith(color: colors.textPrimary),
            ),
          ),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              itemCount: atrasadas.length,
              separatorBuilder: (_, _) =>
                  Divider(height: 1, color: colors.borderSubtle),
              itemBuilder: (context, i) {
                final tarefa = atrasadas[i];
                return InkWell(
                  key: ValueKey('atrasada-${tarefa.id}'),
                  onTap: () => Navigator.of(context).pop(tarefa),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tarefa.titulo,
                                style: AppTextStyles.bodyStrong.copyWith(
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                '${formatarData(tarefa.data)} • '
                                '${formatarHora(tarefa.data)}',
                                style: AppTextStyles.caption.copyWith(
                                  color: colors.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        StatusChip(
                          label: tarefa.tipo.label,
                          tone: tarefa.tipo.tone,
                          uppercase: true,
                        ),
                        Icon(Icons.chevron_right, color: colors.textMuted),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
