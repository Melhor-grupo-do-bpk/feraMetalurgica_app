import 'dart:math';

import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_spacing.dart';
import 'package:fera_metalurgica_app/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

const double _tamanhoIcone = 20;

/// Uma aba da [AppBottomNavBar].
typedef AppNavItem = ({IconData icone, String label});

/// Navegação inferior do app: aba ativa em "pill" laranja.
class AppBottomNavBar extends StatelessWidget {
  /// Cria a navegação com [itens], destacando [indiceAtual].
  const AppBottomNavBar({
    required this.itens,
    required this.indiceAtual,
    required this.onSelecionado,
    super.key,
  });

  /// Abas, na ordem de exibição.
  final List<AppNavItem> itens;

  /// Índice da aba ativa.
  final int indiceAtual;

  /// Chamado com o índice da aba tocada.
  final ValueChanged<int> onSelecionado;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          // As abas ficam no tamanho natural, espalhadas pela largura. Se
          // não couberem (tela estreita ou fonte grande do sistema), cada
          // uma recebe uma fatia igual e o rótulo é cortado com reticências.
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cabem = _larguraNatural(context) <= constraints.maxWidth;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  for (var i = 0; i < itens.length; i++)
                    if (cabem)
                      _botao(i, colors)
                    else
                      Expanded(
                        // `heightFactor: 1`: sem ele, o `Center` ocupa toda
                        // a altura que o Scaffold oferece à barra.
                        child: Center(
                          heightFactor: 1,
                          child: _botao(i, colors),
                        ),
                      ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _botao(int i, AppColors colors) => _NavButton(
    item: itens[i],
    ativo: i == indiceAtual,
    colors: colors,
    onTap: () => onSelecionado(i),
  );

  /// Soma das larguras das abas sem corte: rótulo (ou ícone, se maior)
  /// mais o padding horizontal do [_NavButton].
  double _larguraNatural(BuildContext context) {
    final estilo = DefaultTextStyle.of(
      context,
    ).style.merge(AppTextStyles.label);
    final escala = MediaQuery.textScalerOf(context);
    var total = 0.0;
    for (final item in itens) {
      final texto = TextPainter(
        text: TextSpan(text: item.label, style: estilo),
        textDirection: Directionality.of(context),
        textScaler: escala,
        maxLines: 1,
      )..layout();
      total += max(texto.width, _tamanhoIcone) + 2 * AppSpacing.sm;
      texto.dispose();
    }
    return total;
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.ativo,
    required this.colors,
    required this.onTap,
  });

  final AppNavItem item;
  final bool ativo;
  final AppColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = ativo ? colors.onNavActive : colors.navInactive;
    final radius = BorderRadius.circular(AppSpacing.radiusMd);
    return Semantics(
      selected: ativo,
      button: true,
      child: Material(
        color: ativo ? colors.navActive : Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(item.icone, size: _tamanhoIcone, color: foreground),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label.copyWith(color: foreground),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
