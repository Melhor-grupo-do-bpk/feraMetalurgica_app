import 'dart:async';
import 'dart:ui';

import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Altura da barra sem a área do sistema, como a tab bar do iOS.
const double _alturaBarra = 49;

const double _tamanhoIcone = 26;

/// Uma aba da [AppBottomNavBar]: ícone em contorno (inativa), ícone
/// preenchido (ativa) e rótulo.
typedef AppNavItem = ({IconData icone, IconData iconeAtivo, String label});

/// Navegação inferior no estilo da tab bar clássica do iOS (D-43): fixa
/// embaixo, fundo translúcido com blur e linha fina no topo. A aba ativa
/// usa o ícone preenchido na cor de destaque; as outras, o contorno em
/// cinza. Sem ripple: o toque só esmaece a aba.
///
/// O shell usa `Scaffold.extendBody`, então o conteúdo rola por baixo da
/// barra; as telas das abas somam `MediaQuery.paddingOf(context).bottom` ao
/// espaço do fim da lista.
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

  /// Chamado com o índice da aba tocada, inclusive a que já está ativa.
  final ValueChanged<int> onSelecionado;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.background.withValues(alpha: 0.9),
            border: Border(
              top: BorderSide(
                color: colors.border.withValues(alpha: 0.6),
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: _alturaBarra,
              child: Row(
                children: [
                  for (var i = 0; i < itens.length; i++)
                    Expanded(
                      child: _Aba(
                        item: itens[i],
                        ativa: i == indiceAtual,
                        onTap: () {
                          if (i != indiceAtual) {
                            unawaited(HapticFeedback.selectionClick());
                          }
                          onSelecionado(i);
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Uma aba: ocupa toda a largura e a altura da sua fatia.
class _Aba extends StatefulWidget {
  const _Aba({required this.item, required this.ativa, required this.onTap});

  final AppNavItem item;
  final bool ativa;
  final VoidCallback onTap;

  @override
  State<_Aba> createState() => _AbaState();
}

class _AbaState extends State<_Aba> {
  bool _pressionada = false;

  void _pressionar({required bool pressionada}) {
    if (_pressionada != pressionada) {
      setState(() => _pressionada = pressionada);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final cor = widget.ativa ? colors.navActive : colors.navInactive;
    return Semantics(
      button: true,
      selected: widget.ativa,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _pressionar(pressionada: true),
        onTapUp: (_) => _pressionar(pressionada: false),
        onTapCancel: () => _pressionar(pressionada: false),
        onTap: widget.onTap,
        child: AnimatedOpacity(
          opacity: _pressionada ? 0.5 : 1,
          duration: const Duration(milliseconds: 100),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.ativa ? widget.item.iconeAtivo : widget.item.icone,
                size: _tamanhoIcone,
                color: cor,
              ),
              const SizedBox(height: 2),
              Text(
                widget.item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.tabLabel.copyWith(color: cor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
