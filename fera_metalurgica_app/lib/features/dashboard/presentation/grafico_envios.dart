import 'dart:math';

import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_spacing.dart';
import 'package:fera_metalurgica_app/core/theme/app_text_styles.dart';
import 'package:fera_metalurgica_app/core/utils/date_format.dart';
import 'package:fera_metalurgica_app/core/widgets/section_card.dart';
import 'package:fera_metalurgica_app/features/dashboard/presentation/dashboard_indicadores.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Altura máxima das barras.
const double _alturaBarras = 96;

/// Gráfico de barras "Enviados por mês" do Início (D-45): valor enviado em
/// cada um dos últimos 6 meses. O mês escolhido (de início, o atual) mostra
/// o valor exato e a quantidade acima das barras; tocar numa barra escolhe
/// o mês dela.
class GraficoEnvios extends ConsumerStatefulWidget {
  /// Cria o gráfico.
  const GraficoEnvios({super.key});

  @override
  ConsumerState<GraficoEnvios> createState() => _GraficoEnviosState();
}

class _GraficoEnviosState extends ConsumerState<GraficoEnvios> {
  /// Mês escolhido; `null` é o mais recente.
  int? _escolhido;

  @override
  Widget build(BuildContext context) {
    final envios = ref.watch(enviosPorMesProvider).value;
    if (envios == null || envios.isEmpty) return const SizedBox.shrink();
    final colors = context.colors;
    final indice = min(_escolhido ?? envios.length - 1, envios.length - 1);
    final escolhido = envios[indice];
    final maior = envios.map((e) => e.valor.centavos).reduce(max);
    final quantidade = escolhido.quantidade == 1
        ? '1 orçamento'
        : '${escolhido.quantidade} orçamentos';

    return SectionCard(
      titulo: 'Enviados por mês',
      icone: Icons.bar_chart,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            formatarMesAno(escolhido.mes),
            style: AppTextStyles.label.copyWith(color: colors.textSecondary),
          ),
          Text(
            escolhido.valor.formatado,
            style: AppTextStyles.title.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            quantidade,
            style: AppTextStyles.caption.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final (i, envio) in envios.indexed)
                Expanded(
                  child: _Barra(
                    envio: envio,
                    // Proporção só para desenhar; o valor exibido é o
                    // `Dinheiro` (D-26).
                    fracao: maior == 0 ? 0 : envio.valor.centavos / maior,
                    escolhida: i == indice,
                    onTap: () => setState(() => _escolhido = i),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Barra extends StatelessWidget {
  const _Barra({
    required this.envio,
    required this.fracao,
    required this.escolhida,
    required this.onTap,
  });

  final EnvioDoMes envio;
  final double fracao;
  final bool escolhida;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      selected: escolhida,
      label: '${formatarMesAno(envio.mes)}: ${envio.valor.formatado}',
      excludeSemantics: true,
      child: GestureDetector(
        key: ValueKey('grafico-mes-${envio.mes.year}-${envio.mes.month}'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
          child: Column(
            children: [
              SizedBox(
                height: _alturaBarras,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: double.infinity,
                    // Mês sem envio ainda mostra um traço na base.
                    height: max(4, _alturaBarras * fracao),
                    decoration: BoxDecoration(
                      color: escolhida ? colors.primary : colors.progressTrack,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppSpacing.radiusXs),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                formatarMesCurto(envio.mes),
                style:
                    (escolhida
                            ? AppTextStyles.labelStrong
                            : AppTextStyles.label)
                        .copyWith(
                          color: escolhida
                              ? colors.textPrimary
                              : colors.textSecondary,
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
