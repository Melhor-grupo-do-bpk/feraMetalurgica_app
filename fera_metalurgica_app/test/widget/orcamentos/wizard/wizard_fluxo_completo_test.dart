import 'dart:async';

import 'package:fera_metalurgica_app/core/router/app_router.dart';
import 'package:fera_metalurgica_app/features/orcamentos/orcamentos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fera_app_de_teste.dart';
import 'wizard_teste_helpers.dart';

/// Critério de aceite da F2, no app completo com os dados de exemplo: o
/// wizard em stub cria o primeiro orçamento do dia (`DDMMAA-01`), que abre
/// nos detalhes e aparece na lista sem reiniciar o app.
void main() {
  testWidgets('fluxo completo cria o orçamento -01 e ele aparece na lista', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(800, 2400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    appRouter.go(AppRoutes.orcamentos);
    await tester.pumpWidget(
      await feraAppDeTeste(
        themeMode: ThemeMode.light,
        agora: DateTime(2026, 10, 26, 10),
      ),
    );
    await tester.pumpAndSettle();
    // Os dois exemplos, de dias anteriores.
    expect(find.text('241026-01'), findsOneWidget);
    expect(find.text('251026-01'), findsOneWidget);

    unawaited(appRouter.push(AppRoutes.novoOrcamento()));
    await tester.pumpAndSettle();
    await preencherStub(tester, cliente: 'Construtora Horizonte Ltda');
    await tocar(tester, find.text('Finalizar'));

    // Detalhes do novo orçamento, no lugar do wizard.
    expect(find.byType(OrcamentoWizardPage), findsNothing);
    expect(find.byType(OrcamentoDetalhesPage), findsOneWidget);
    expect(find.text('261026-01'), findsOneWidget);
    expect(find.text(r'R$ 1.098,00'), findsOneWidget);

    // Voltar dos detalhes leva à lista, que já mostra o orçamento.
    await tocar(tester, find.byTooltip('Voltar'));
    expect(find.byType(OrcamentosListaPage), findsOneWidget);
    expect(find.text('261026-01'), findsOneWidget);
  });
}
