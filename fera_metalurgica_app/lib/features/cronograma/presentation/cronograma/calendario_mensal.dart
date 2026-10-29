import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_spacing.dart';
import 'package:fera_metalurgica_app/core/theme/app_text_styles.dart';
import 'package:fera_metalurgica_app/core/utils/date_format.dart';
import 'package:fera_metalurgica_app/features/cronograma/presentation/cronograma/calendario_mes.dart';
import 'package:flutter/material.dart';

const List<String> _letrasDaSemana = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];

/// Calendário do mês feito à mão (D-14, RF-80): cabeçalho "Outubro 2023"
/// com ‹ ›, linha D S T Q Q S S e a grade de [diasDaGrade].
///
/// Dias de outros meses ficam esmaecidos, o [diaSelecionado] fica numa
/// pílula escura e os [diasComPonto] (fora o selecionado) ganham um ponto.
class CalendarioMensal extends StatelessWidget {
  /// Cria o calendário.
  const CalendarioMensal({
    required this.mesExibido,
    required this.diaSelecionado,
    required this.diasComPonto,
    required this.onDiaSelecionado,
    required this.onMudarMes,
    super.key,
  });

  /// Mês exibido (só ano e mês contam).
  final DateTime mesExibido;

  /// Dia em destaque.
  final DateTime diaSelecionado;

  /// Dias (sem hora) que levam o ponto de tarefa pendente.
  final Set<DateTime> diasComPonto;

  /// Toque num dia da grade.
  final ValueChanged<DateTime> onDiaSelecionado;

  /// Toque em ‹ (-1) ou › (+1).
  final ValueChanged<int> onMudarMes;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dias = diasDaGrade(mesExibido);

    // Fica dentro de um card decorado: o `Material` transparente faz o
    // efeito de toque dos dias aparecer.
    return Material(
      type: MaterialType.transparency,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  formatarMesAno(mesExibido),
                  style: AppTextStyles.title.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => onMudarMes(-1),
                tooltip: 'Mês anterior',
                icon: Icon(Icons.chevron_left, color: colors.textPrimary),
              ),
              IconButton(
                onPressed: () => onMudarMes(1),
                tooltip: 'Próximo mês',
                icon: Icon(Icons.chevron_right, color: colors.textPrimary),
              ),
            ],
          ),
          Divider(color: colors.borderSubtle, height: AppSpacing.md),
          Row(
            children: [
              for (final letra in _letrasDaSemana)
                Expanded(
                  child: Text(
                    letra,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.label.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          for (var semana = 0; semana < dias.length; semana += 7)
            Row(
              children: [
                for (final dia in dias.sublist(semana, semana + 7))
                  Expanded(
                    child: _Dia(
                      dia: dia,
                      doMes: dia.month == mesExibido.month,
                      selecionado: mesmoDia(dia, diaSelecionado),
                      comPonto: diasComPonto.contains(dia),
                      onTap: () => onDiaSelecionado(dia),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Dia extends StatelessWidget {
  const _Dia({
    required this.dia,
    required this.doMes,
    required this.selecionado,
    required this.comPonto,
    required this.onTap,
  });

  final DateTime dia;
  final bool doMes;
  final bool selecionado;
  final bool comPonto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final corTexto = selecionado
        ? colors.onDarkSurface
        : (doMes ? colors.textPrimary : colors.textMuted);

    return Semantics(
      selected: selecionado,
      label: formatarData(dia),
      excludeSemantics: true,
      button: true,
      child: InkWell(
        key: ValueKey('calendario-dia-${formatarData(dia)}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        child: SizedBox(
          height: 48,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                constraints: const BoxConstraints(minWidth: AppSpacing.xl),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxs,
                  vertical: AppSpacing.xxs,
                ),
                decoration: selecionado
                    ? BoxDecoration(
                        color: colors.darkSurface,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusFull,
                        ),
                      )
                    : null,
                child: Text(
                  '${dia.day}',
                  maxLines: 1,
                  softWrap: false,
                  textAlign: TextAlign.center,
                  style:
                      (selecionado
                              ? AppTextStyles.bodyStrong
                              : AppTextStyles.body)
                          .copyWith(color: corTexto),
                ),
              ),
              const SizedBox(height: 2),
              Container(
                key: comPonto && !selecionado
                    ? const ValueKey('calendario-ponto')
                    : null,
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: comPonto && !selecionado
                      ? colors.brand
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
