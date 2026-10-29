import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_spacing.dart';
import 'package:fera_metalurgica_app/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Linha da timeline do cronograma: horário + marcador à esquerda e card
/// da tarefa à direita, com faixa colorida de destaque.
class TimelineTile extends StatelessWidget {
  /// Cria a linha da timeline.
  const TimelineTile({
    required this.horario,
    required this.titulo,
    this.descricao,
    this.tag,
    this.acao,
    this.corDestaque,
    this.concluida = false,
    this.ultimo = false,
    this.onMarcadorPressed,
    super.key,
  });

  /// Horário exibido à esquerda (ex: "09:00").
  final String horario;

  /// Título da tarefa.
  final String titulo;

  /// Texto secundário (ex: "Cliente: Indústrias Apex S/A").
  final String? descricao;

  /// Tag no canto superior direito (normalmente um `StatusChip`).
  final Widget? tag;

  /// Ação abaixo da descrição (ex: botão "Ver Detalhes").
  final Widget? acao;

  /// Cor do marcador e da faixa lateral; padrão: `darkSurface` do tema.
  final Color? corDestaque;

  /// Tarefa concluída: texto riscado, opacidade reduzida e ícone de check.
  final bool concluida;

  /// Último item da lista: não desenha a linha abaixo do marcador.
  final bool ultimo;

  /// Toque no marcador (ex: alternar `concluida`, RF-84). Com ele, o
  /// marcador vira um botão de 48 dp com tooltip (RNF-06); sem ele, é só
  /// desenho.
  final VoidCallback? onMarcadorPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final destaque = concluida
        ? colors.border
        : (corDestaque ?? colors.darkSurface);
    final riscado = concluida ? TextDecoration.lineThrough : null;
    final marcador = Container(
      key: const ValueKey('timeline-dot'),
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: destaque, shape: BoxShape.circle),
    );

    return Opacity(
      opacity: concluida ? 0.6 : 1,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 60,
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    horario,
                    style:
                        (concluida
                                ? AppTextStyles.labelMedium
                                : AppTextStyles.labelStrong)
                            .copyWith(
                              color: concluida
                                  ? colors.textSecondary
                                  : colors.textPrimary,
                              decoration: riscado,
                            ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  if (onMarcadorPressed == null)
                    marcador
                  else
                    IconButton(
                      key: const ValueKey('timeline-marcador'),
                      onPressed: onMarcadorPressed,
                      tooltip: concluida
                          ? 'Marcar como pendente'
                          : 'Marcar como concluída',
                      icon: marcador,
                    ),
                  if (!ultimo)
                    Expanded(
                      child: Container(
                        key: const ValueKey('timeline-line'),
                        width: 2,
                        color: colors.timelineLine,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: ultimo ? 0 : AppSpacing.lg),
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: concluida ? colors.surfaceMuted : colors.background,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(color: colors.borderSubtle),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ColoredBox(
                        color: destaque,
                        child: const SizedBox(width: 4),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      titulo,
                                      style:
                                          (concluida
                                                  ? AppTextStyles.body
                                                  : AppTextStyles.bodyStrong)
                                              .copyWith(
                                                color: concluida
                                                    ? colors.textSecondary
                                                    : colors.textPrimary,
                                                decoration: riscado,
                                              ),
                                    ),
                                  ),
                                  if (concluida)
                                    Icon(
                                      Icons.check_circle_outline,
                                      size: 20,
                                      color: colors.textMuted,
                                    )
                                  else
                                    ?tag,
                                ],
                              ),
                              if (descricao != null) ...[
                                const SizedBox(height: AppSpacing.xxs),
                                Text(
                                  descricao!,
                                  style: AppTextStyles.caption.copyWith(
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ],
                              if (acao != null && !concluida) ...[
                                const SizedBox(height: AppSpacing.xs),
                                acao!,
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
