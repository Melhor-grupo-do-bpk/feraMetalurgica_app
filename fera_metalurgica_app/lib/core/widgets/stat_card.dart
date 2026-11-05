import 'dart:math';

import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_spacing.dart';
import 'package:fera_metalurgica_app/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Card de indicador do dashboard (ex: "Aprovados — 45").
class StatCard extends StatelessWidget {
  /// Cria o indicador.
  const StatCard({
    required this.label,
    required this.valor,
    required this.icone,
    this.onTap,
    this.tamanhoValor,
    super.key,
  });

  /// Descrição do indicador.
  final String label;

  /// Valor exibido (já formatado, ex: "08").
  final String valor;

  /// Ícone do canto superior direito.
  final IconData icone;

  /// Ação ao tocar no card.
  final VoidCallback? onTap;

  /// Tamanho da fonte do valor; sem ele, o de [AppTextStyles.statValue].
  /// Os cards de uma tela usam o mesmo, vindo de [tamanhoQueCabe].
  final double? tamanhoValor;

  /// Maior tamanho de fonte, até o de [AppTextStyles.statValue], em que
  /// todos os [valores] cabem numa linha de um card de [larguraCard].
  static double tamanhoQueCabe(
    BuildContext context, {
    required Iterable<String> valores,
    required double larguraCard,
  }) {
    final estilo = DefaultTextStyle.of(
      context,
    ).style.merge(AppTextStyles.statValue);
    final textScaler = MediaQuery.textScalerOf(context);
    var maior = 0.0;
    for (final valor in valores) {
      final pintor = TextPainter(
        text: TextSpan(text: valor, style: estilo),
        textDirection: TextDirection.ltr,
        textScaler: textScaler,
        maxLines: 1,
      )..layout();
      maior = max(maior, pintor.width);
      pintor.dispose();
    }
    final largura = larguraCard - 2 * AppSpacing.md;
    final tamanho = AppTextStyles.statValue.fontSize!;
    return maior <= largura ? tamanho : tamanho * largura / maior;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = BorderRadius.circular(AppSpacing.radiusMd);
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: colors.border),
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: AppTextStyles.label.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Icon(icone, size: 20, color: colors.textSecondary),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              // O ícone fica na linha do rótulo para o valor ter a largura
              // toda do card. O `FittedBox` só cobre o arredondamento de
              // `tamanhoQueCabe`.
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  valor,
                  maxLines: 1,
                  softWrap: false,
                  style: AppTextStyles.statValue.copyWith(
                    color: colors.textPrimary,
                    fontSize: tamanhoValor,
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
