import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_spacing.dart';
import 'package:fera_metalurgica_app/core/theme/app_text_styles.dart';
import 'package:fera_metalurgica_app/core/utils/date_format.dart';
import 'package:fera_metalurgica_app/features/cronograma/presentation/cronograma/agenda_filtro.dart';
import 'package:flutter/material.dart';

/// Atalhos horizontais de dia (RF-82): 7 dias a partir do
/// [diaSelecionado], que fica em destaque no primeiro atalho.
class AtalhosDia extends StatelessWidget {
  /// Cria os atalhos.
  const AtalhosDia({
    required this.diaSelecionado,
    required this.hoje,
    required this.onDiaSelecionado,
    super.key,
  });

  /// Primeiro dia dos atalhos (em destaque).
  final DateTime diaSelecionado;

  /// "Hoje", para os rótulos "Hoje, 9 Out" e "Amanhã, 10 Out".
  final DateTime hoje;

  /// Toque num atalho.
  final ValueChanged<DateTime> onDiaSelecionado;

  @override
  Widget build(BuildContext context) {
    final dias = [
      for (var i = 0; i < 7; i++)
        DateTime(
          diaSelecionado.year,
          diaSelecionado.month,
          diaSelecionado.day + i,
        ),
    ];
    return SizedBox(
      height: 48,
      // São só 7 atalhos: um `Row` rolável basta, sem lista preguiçosa.
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          spacing: AppSpacing.xs,
          children: [
            for (final (i, dia) in dias.indexed)
              _Atalho(
                key: ValueKey('atalho-${formatarData(dia)}'),
                rotulo: rotuloAtalho(dia, hoje),
                selecionado: i == 0,
                onTap: () => onDiaSelecionado(dia),
              ),
          ],
        ),
      ),
    );
  }
}

class _Atalho extends StatelessWidget {
  const _Atalho({
    required this.rotulo,
    required this.selecionado,
    required this.onTap,
    super.key,
  });

  final String rotulo;
  final bool selecionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final forma = BorderRadius.circular(AppSpacing.radiusFull);
    return Semantics(
      selected: selecionado,
      button: true,
      child: Material(
        color: selecionado ? colors.darkSurface : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: forma,
          side: BorderSide(
            color: selecionado ? colors.darkSurface : colors.border,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: forma,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md + AppSpacing.xxs,
            ),
            child: Center(
              child: Text(
                rotulo,
                style:
                    (selecionado
                            ? AppTextStyles.labelStrong
                            : AppTextStyles.label)
                        .copyWith(
                          color: selecionado
                              ? colors.onDarkSurface
                              : colors.textPrimary,
                        ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
