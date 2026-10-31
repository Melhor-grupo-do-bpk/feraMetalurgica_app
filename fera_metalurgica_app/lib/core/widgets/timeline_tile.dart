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

  /// Largura mínima da linha para a etiqueta caber ao lado do título sem
  /// espremê-lo. Abaixo dela (ex: 360 e 412 dp), a etiqueta vai para cima
  /// do título (HO-V2-E-03).
  static const double _larguraLadoALado = 440;

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

    return LayoutBuilder(
      builder: (context, constraints) => Opacity(
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
                      color: concluida
                          ? colors.surfaceMuted
                          : colors.background,
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
                                _Cabecalho(
                                  titulo: Text(
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
                                  // Concluída: o check no lugar da etiqueta.
                                  lateral: concluida
                                      ? Icon(
                                          Icons.check_circle_outline,
                                          size: 20,
                                          color: colors.textMuted,
                                        )
                                      : null,
                                  tag: concluida ? null : tag,
                                  empilhar:
                                      constraints.maxWidth < _larguraLadoALado,
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
      ),
    );
  }
}

/// Título do cartão com a etiqueta: à direita do título, ou acima dele
/// quando [empilhar], para o título usar a largura toda em vez de quebrar
/// a cada sílaba.
class _Cabecalho extends StatelessWidget {
  const _Cabecalho({
    required this.titulo,
    required this.empilhar,
    this.lateral,
    this.tag,
  });

  final Widget titulo;

  /// Etiqueta acima do título.
  final bool empilhar;

  /// Ícone pequeno sempre à direita (o check da concluída).
  final Widget? lateral;

  final Widget? tag;

  @override
  Widget build(BuildContext context) {
    final tag = this.tag;
    final acima = tag != null && empilhar;
    final linha = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: titulo),
        ?lateral,
        if (!acima) ?tag,
      ],
    );
    if (!acima) return linha;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        tag,
        const SizedBox(height: AppSpacing.xs),
        linha,
      ],
    );
  }
}
