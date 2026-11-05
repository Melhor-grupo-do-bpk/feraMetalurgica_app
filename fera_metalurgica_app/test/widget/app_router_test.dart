import 'dart:async';

import 'package:fera_metalurgica_app/core/router/app_router.dart';
import 'package:fera_metalurgica_app/core/widgets/app_bottom_nav_bar.dart';
import 'package:fera_metalurgica_app/features/cronograma/cronograma.dart';
import 'package:fera_metalurgica_app/features/dashboard/dashboard.dart';
import 'package:fera_metalurgica_app/features/empresa/empresa.dart';
import 'package:fera_metalurgica_app/features/mais/mais.dart';
import 'package:fera_metalurgica_app/features/materiais/materiais.dart';
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
    (AppRoutes.agenda, CronogramaPage),
    (AppRoutes.mais, MaisPage),
    (AppRoutes.materiais, MateriaisPage),
    (AppRoutes.empresa, EmpresaPage),
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
    (AppRoutes.material(), MaterialFormPage),
  ];
  for (final (rota, pagina) in telasCheias) {
    testWidgets('$rota abre $pagina em tela cheia', (tester) async {
      await abrir(tester, rota);

      expect(find.byType(pagina), findsOneWidget);
      expect(find.byType(AppBottomNavBar), findsNothing);
    });
  }

  testWidgets('parâmetros chegam às páginas', (tester) async {
    await abrir(tester, AppRoutes.novoOrcamento());
    final novo = tester.widget<OrcamentoWizardPage>(
      find.byType(OrcamentoWizardPage),
    );
    expect(novo.orcamentoId, isNull);

    await abrir(tester, AppRoutes.editarOrcamento('00482'));
    final edicao = tester.widget<OrcamentoWizardPage>(
      find.byType(OrcamentoWizardPage),
    );
    expect(edicao.orcamentoId, '00482');

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

    await abrir(tester, AppRoutes.tarefa(orcamentoId: 'o1'));
    final tarefa = tester.widget<TarefaFormPage>(find.byType(TarefaFormPage));
    expect((tarefa.tarefaId, tarefa.orcamentoId), (null, 'o1'));

    await abrir(tester, AppRoutes.material(id: 'm1'));
    expect(
      tester.widget<MaterialFormPage>(find.byType(MaterialFormPage)).materialId,
      'm1',
    );
  });

  testWidgets('voltar de uma tela cheia retorna à aba de origem', (
    tester,
  ) async {
    await abrir(tester, AppRoutes.orcamentos);
    unawaited(appRouter.push(AppRoutes.detalhesOrcamento('00482')));
    await tester.pumpAndSettle();
    expect(find.byType(OrcamentoDetalhesPage), findsOneWidget);

    // O voltar da top bar (o id não existe: a tela também tem "Voltar").
    await tester.tap(find.byIcon(Icons.arrow_back).first);
    await tester.pumpAndSettle();

    expect(find.byType(OrcamentosListaPage), findsOneWidget);
    expect(find.byType(AppBottomNavBar), findsOneWidget);
  });

  testWidgets('Mais abre Materiais e Dados da empresa (D-31)', (tester) async {
    await abrir(tester, AppRoutes.mais);

    await tester.tap(find.text('Materiais'));
    await tester.pumpAndSettle();
    expect(find.byType(MateriaisPage), findsOneWidget);

    await abrir(tester, AppRoutes.mais);
    await tester.tap(find.text('Dados da empresa'));
    await tester.pumpAndSettle();
    expect(find.byType(EmpresaPage), findsOneWidget);
  });

  testWidgets('sem empresa completa, o wizard leva a Dados da empresa', (
    tester,
  ) async {
    appRouter.go(AppRoutes.orcamentos);
    await tester.pumpWidget(await feraAppDeTeste(semEmpresa: true));
    await tester.pumpAndSettle();

    unawaited(appRouter.push(AppRoutes.novoOrcamento()));
    await tester.pumpAndSettle();
    expect(find.byType(OrcamentoWizardPage), findsNothing);
    expect(find.byType(EmpresaPage), findsOneWidget);

    unawaited(appRouter.push(AppRoutes.editarOrcamento('qualquer')));
    await tester.pumpAndSettle();
    expect(find.byType(OrcamentoWizardPage), findsNothing);
    expect(find.byType(EmpresaPage), findsOneWidget);
  });
}
