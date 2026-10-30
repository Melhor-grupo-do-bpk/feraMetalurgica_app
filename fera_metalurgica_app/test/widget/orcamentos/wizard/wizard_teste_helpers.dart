import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Rola até [finder], toca e espera as animações.
Future<void> tocar(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Botão "Continuar" do rodapé.
Finder get continuar => find.text('Continuar');

/// Passa pelas 4 etapas do wizard em stub: escolhe [cliente] na busca,
/// adiciona o produto de teste e chega à prévia.
Future<void> preencherStub(
  WidgetTester tester, {
  String cliente = 'João da Silva',
}) async {
  await tester.enterText(
    find.byKey(const ValueKey('wizard-busca-cliente')),
    cliente,
  );
  await tester.pumpAndSettle();
  await tocar(
    tester,
    find.descendant(
      of: find.byKey(const ValueKey('wizard-resultados-cliente')),
      matching: find.text(cliente),
    ),
  );
  await tocar(tester, continuar);
  await tocar(tester, find.text('Adicionar produto de teste'));
  await tocar(tester, continuar);
  await tocar(tester, continuar);
}
