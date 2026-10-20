import 'package:fera_metalurgica_app/core/router/app_routes.dart';
import 'package:fera_metalurgica_app/core/widgets/app_bottom_nav_bar.dart';
import 'package:fera_metalurgica_app/features/catalogo/catalogo.dart';
import 'package:fera_metalurgica_app/features/dashboard/dashboard.dart';
import 'package:fera_metalurgica_app/features/mais/mais.dart';
import 'package:fera_metalurgica_app/features/orcamentos/orcamentos.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

export 'app_routes.dart';

/// Abas da navegação inferior, na mesma ordem dos branches do shell.
const List<AppNavItem> _abas = [
  (icone: Icons.home_outlined, label: 'Início'),
  (icone: Icons.request_quote_outlined, label: 'Orçamentos'),
  (icone: Icons.shopping_cart_outlined, label: 'Catálogo'),
  (icone: Icons.menu, label: 'Mais'),
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
        StatefulShellBranch(routes: [catalogoRoute]),
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
      body: navigationShell,
      bottomNavigationBar: AppBottomNavBar(
        itens: _abas,
        indiceAtual: navigationShell.currentIndex,
        onSelecionado: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}
