import 'dart:async';

import 'package:fera_metalurgica_app/core/router/app_router.dart';
import 'package:fera_metalurgica_app/core/widgets/app_bottom_nav_bar.dart';
import 'package:fera_metalurgica_app/features/catalogo/catalogo.dart';
import 'package:fera_metalurgica_app/features/cronograma/cronograma.dart';
import 'package:fera_metalurgica_app/features/dashboard/dashboard.dart';
import 'package:fera_metalurgica_app/features/mais/mais.dart';
import 'package:fera_metalurgica_app/features/orcamentos/orcamentos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fera_app_de_teste.dart';

/// Garante que cada helper de `AppRoutes` (D-11) abre a tela certa, com os
/// parâmetros certos, dentro ou fora do shell.
void main() {
  Future<void> abrir(WidgetTester tester, String rota) async {
    appRouter.go(rota);
    await tester.pumpWidget(await feraAppDeTeste());
    await tester.pumpAndSettle();
  }

  final abas = <(String, Type)>[
    (AppRoutes.dashboard, DashboardPage),
    (AppRoutes.orcamentos, OrcamentosListaPage),
    (AppRoutes.catalogo, CatalogoPage),
    (AppRoutes.mais, MaisPage),
    (AppRoutes.cronograma, CronogramaPage),
  ];
  for (final (rota, pagina) in abas) {
    testWidgets('$rota abre $pagina com a navegação inferior', (tester) async {
      await abrir(tester, rota);

      expect(find.byType(pagina), findsOneWidget);
      expect(find.byType(AppBottomNavBar), findsOneWidget);
    });
  }

  final telasCheias = <(String, Type)>[
    (AppRoutes.novoOrcamento(), OrcamentoWizardPage),
    (AppRoutes.detalhesOrcamento('00482'), OrcamentoDetalhesPage),
    (AppRoutes.editarOrcamento('00482'), OrcamentoWizardPage),
    (AppRoutes.pdfOrcamento('00482'), OrcamentoPdfPage),
    (AppRoutes.tarefa(), TarefaFormPage),
  ];
  for (final (rota, pagina) in telasCheias) {
    testWidgets('$rota abre $pagina em tela cheia', (tester) async {
      await abrir(tester, rota);

      expect(find.byType(pagina), findsOneWidget);
      expect(find.byType(AppBottomNavBar), findsNothing);
    });
  }

  testWidgets('parâmetros chegam às páginas', (tester) async {
    await abrir(tester, AppRoutes.novoOrcamento(produtoId: 'p1'));
    final novo = tester.widget<OrcamentoWizardPage>(
      find.byType(OrcamentoWizardPage),
    );
    expect((novo.orcamentoId, novo.produtoId), (null, 'p1'));

    await abrir(tester, AppRoutes.editarOrcamento('00482'));
    final edicao = tester.widget<OrcamentoWizardPage>(
      find.byType(OrcamentoWizardPage),
    );
    expect((edicao.orcamentoId, edicao.produtoId), ('00482', null));

    await abrir(tester, AppRoutes.detalhesOrcamento('00481'));
    expect(
      tester
          .widget<OrcamentoDetalhesPage>(find.byType(OrcamentoDetalhesPage))
          .orcamentoId,
      '00481',
    );

    await abrir(tester, AppRoutes.tarefa(id: 't1'));
    expect(
      tester.widget<TarefaFormPage>(find.byType(TarefaFormPage)).tarefaId,
      't1',
    );
  });

  testWidgets('voltar de uma tela cheia retorna à aba de origem', (
    tester,
  ) async {
    await abrir(tester, AppRoutes.orcamentos);
    unawaited(appRouter.push(AppRoutes.detalhesOrcamento('00482')));
    await tester.pumpAndSettle();
    expect(find.byType(OrcamentoDetalhesPage), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.byType(OrcamentosListaPage), findsOneWidget);
    expect(find.byType(AppBottomNavBar), findsOneWidget);
  });

  testWidgets('Mais abre o cronograma', (tester) async {
    await abrir(tester, AppRoutes.mais);

    await tester.tap(find.text('Cronograma'));
    await tester.pumpAndSettle();

    expect(find.byType(CronogramaPage), findsOneWidget);
  });
}
