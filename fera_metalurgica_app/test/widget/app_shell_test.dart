import 'package:fera_metalurgica_app/core/router/app_router.dart';
import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/widgets/app_bottom_nav_bar.dart';
import 'package:fera_metalurgica_app/features/catalogo/catalogo.dart';
import 'package:fera_metalurgica_app/features/dashboard/dashboard.dart';
import 'package:fera_metalurgica_app/features/mais/mais.dart';
import 'package:fera_metalurgica_app/features/orcamentos/orcamentos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fera_app_de_teste.dart';

void main() {
  for (final (modo, cores) in [
    (ThemeMode.light, AppColors.light),
    (ThemeMode.dark, AppColors.dark),
  ]) {
    testWidgets('abre com as 4 abas e navega entre elas (${modo.name})', (
      tester,
    ) async {
      appRouter.go(AppRoutes.dashboard);
      await tester.pumpWidget(await feraAppDeTeste(themeMode: modo));
      await tester.pumpAndSettle();

      final nav = find.byType(AppBottomNavBar);
      for (final aba in ['Início', 'Orçamentos', 'Catálogo', 'Mais']) {
        expect(
          find.descendant(of: nav, matching: find.text(aba)),
          findsOneWidget,
        );
      }
      expect(find.byType(DashboardPage), findsOneWidget);

      final context = tester.element(find.byType(DashboardPage));
      expect(Theme.of(context).brightness, switch (modo) {
        ThemeMode.dark => Brightness.dark,
        _ => Brightness.light,
      });
      expect(Theme.of(context).scaffoldBackgroundColor, cores.background);

      for (final (aba, rota, pagina) in [
        ('Orçamentos', AppRoutes.orcamentos, OrcamentosListaPage),
        ('Catálogo', AppRoutes.catalogo, CatalogoPage),
        ('Mais', AppRoutes.mais, MaisPage),
      ]) {
        await tester.tap(find.descendant(of: nav, matching: find.text(aba)));
        await tester.pumpAndSettle();

        expect(appRouter.routerDelegate.currentConfiguration.uri.path, rota);
        expect(find.byType(pagina), findsOneWidget);
      }

      await tester.tap(find.descendant(of: nav, matching: find.text('Início')));
      await tester.pumpAndSettle();
      expect(find.byType(DashboardPage), findsOneWidget);
    });
  }
}
