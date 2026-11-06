import 'dart:async';

import 'package:fera_metalurgica_app/core/router/app_router.dart';
import 'package:fera_metalurgica_app/features/orcamentos/orcamentos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fera_app_de_teste.dart';
import 'wizard_teste_helpers.dart';

/// No app completo com os dados de exemplo: o wizard cria o primeiro
/// orçamento do dia (`DDMMAA-01`), que abre nos detalhes e aparece na lista
/// sem reiniciar o app; e a edição grava a rev. 2, que os detalhes mostram
/// ao voltar.
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
    // Um produto sem adicionais repete o valor nos totais (D-39); confere
    // a linha "Total geral".
    expect(
      find.descendant(
        of: find
            .ancestor(of: find.text('Total geral'), matching: find.byType(Row))
            .first,
        matching: find.text(r'R$ 1.098,00'),
      ),
      findsOneWidget,
    );

    // Voltar dos detalhes leva à lista, que já mostra o orçamento.
    await tocar(tester, find.byTooltip('Voltar'));
    expect(find.byType(OrcamentosListaPage), findsOneWidget);
    expect(find.text('261026-01'), findsOneWidget);
  });

  testWidgets('editar o exemplo C volta aos detalhes com a rev. 2', (
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
    await tocar(tester, find.text('241026-01'));
    expect(find.byType(OrcamentoDetalhesPage), findsOneWidget);
    expect(find.text(r'R$ 3.630,80'), findsOneWidget);

    await tocar(tester, find.text('Editar'));
    expect(find.text('Editar Orçamento'), findsOneWidget);
    await tocar(tester, continuar);
    await tocar(tester, continuar);
    // Combustível de 50,00 para 75,00: + R$ 25,00.
    final combustivel = find.descendant(
      of: find.byKey(const ValueKey('valores-combustivel')),
      matching: find.byType(EditableText),
    );
    await tester.enterText(combustivel, '75,00');
    await tester.pumpAndSettle();
    await tocar(tester, continuar);
    expect(find.text('Nº 241026-01 rev. 2'), findsOneWidget);
    await tocar(tester, find.text('Salvar alterações'));

    // De volta aos mesmos detalhes, já com a revisão e os totais novos.
    expect(find.byType(OrcamentoWizardPage), findsNothing);
    expect(find.byType(OrcamentoDetalhesPage), findsOneWidget);
    expect(find.text('241026-01 rev. 2'), findsOneWidget);
    expect(find.text(r'R$ 3.655,80'), findsOneWidget);
    expect(find.text(r'R$ 3.630,80'), findsNothing);

    // A lista também já mostra a revisão.
    await tocar(tester, find.byTooltip('Voltar'));
    expect(find.byType(OrcamentosListaPage), findsOneWidget);
    expect(find.text(r'R$ 3.655,80'), findsOneWidget);
  });
}
