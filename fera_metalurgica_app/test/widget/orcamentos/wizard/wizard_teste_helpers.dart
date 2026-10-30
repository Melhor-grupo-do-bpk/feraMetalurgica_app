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
  await tocar(tester, find.text(cliente));
  await tocar(tester, continuar);
  // Etapa 2 (V2-A): 3 produtos, base R$ 150,00, uma peça de 120 × 60 cm
  // em granito (R$ 300,00/m²): R$ 366,00 por produto, R$ 1.098,00 no item.
  await tocar(tester, find.text('Adicionar produto'));
  for (final (chave, texto) in [
    ('produto-descricao', 'Produto de teste'),
    ('produto-quantidade', '3'),
    ('produto-preco-base', '150,00'),
    ('peca-descricao', 'Placa'),
  ]) {
    await tester.enterText(find.byKey(ValueKey(chave)), texto);
  }
  await tocar(tester, find.byKey(const ValueKey('peca-material')));
  await tocar(tester, find.text('Granito - variedade B - 2 cm'));
  await tester.enterText(find.byKey(const ValueKey('peca-comprimento')), '120');
  await tester.enterText(find.byKey(const ValueKey('peca-largura')), '60');
  await tocar(tester, find.text('Adicionar peça'));
  await tocar(tester, find.text('Adicionar produto'));
  await tocar(tester, continuar);
  await tocar(tester, continuar);
}
