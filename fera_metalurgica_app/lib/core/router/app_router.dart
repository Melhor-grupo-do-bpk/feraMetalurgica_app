import 'dart:async';

import 'package:fera_metalurgica_app/core/router/app_routes.dart';
import 'package:fera_metalurgica_app/core/widgets/app_bottom_nav_bar.dart';
import 'package:fera_metalurgica_app/features/cronograma/cronograma.dart';
import 'package:fera_metalurgica_app/features/dashboard/dashboard.dart';
import 'package:fera_metalurgica_app/features/mais/mais.dart';
import 'package:fera_metalurgica_app/features/orcamentos/orcamentos.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

export 'app_routes.dart';

/// Abas da navegação inferior (D-31), na mesma ordem dos branches do
/// shell.
const List<AppNavItem> _abas = [
  (
    icone: CupertinoIcons.house,
    iconeAtivo: CupertinoIcons.house_fill,
    label: 'Início',
  ),
  (
    icone: CupertinoIcons.doc_text,
    iconeAtivo: CupertinoIcons.doc_text_fill,
    label: 'Orçamentos',
  ),
  (
    icone: CupertinoIcons.calendar_circle,
    iconeAtivo: CupertinoIcons.calendar_circle_fill,
    label: 'Agenda',
  ),
  (
    icone: CupertinoIcons.ellipsis_circle,
    iconeAtivo: CupertinoIcons.ellipsis_circle_fill,
    label: 'Mais',
  ),
];

/// Instância única de roteamento do app, usada por `MaterialApp.router`.
///
/// Só compõe as rotas que cada feature declara em
/// `presentation/<feature>_routes.dart` (D-12). Congelado após a F1.
final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: AppRoutes.dashboard,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(routes: [dashboardRoute]),
        StatefulShellBranch(routes: [orcamentosRoute]),
        StatefulShellBranch(routes: [cronogramaRoute]),
        StatefulShellBranch(routes: [maisRoute]),
      ],
    ),
  ],
);

/// Estrutura comum às abas: conteúdo da aba ativa + navegação inferior.
class AppShell extends StatelessWidget {
  /// Cria o shell em volta de [navigationShell].
  const AppShell({required this.navigationShell, super.key});

  /// Shell do go_router que mantém o estado de cada aba.
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // O conteúdo rola por baixo da barra translúcida (D-43).
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: AppBottomNavBar(
        itens: _abas,
        indiceAtual: navigationShell.currentIndex,
        onSelecionado: (index) {
          if (index == navigationShell.currentIndex) _rolarAoTopo(index);
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }

  /// Tocar de novo na aba ativa leva as listas dela ao topo, como no iOS
  /// (a volta à raiz da aba é o `initialLocation` do `goBranch`).
  void _rolarAoTopo(int index) {
    final navegador = navigationShell.route.branches[index].navigatorKey;
    void visitar(Element elemento) {
      if (elemento case StatefulElement(
        state: final ScrollableState rolavel,
      ) when rolavel.position.axis == Axis.vertical) {
        unawaited(
          rolavel.position.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          ),
        );
      }
      elemento.visitChildElements(visitar);
    }

    navegador.currentContext?.visitChildElements(visitar);
  }
}
