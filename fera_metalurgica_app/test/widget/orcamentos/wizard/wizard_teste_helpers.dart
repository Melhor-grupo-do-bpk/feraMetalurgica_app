import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Rola até [finder], toca e espera as animações.
Future<void> tocar(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Digita [texto] no campo de chave [chave].
Future<void> digitar(WidgetTester tester, String chave, String texto) async {
  final campo = find.byKey(Key(chave));
  await tester.ensureVisible(campo);
  await tester.enterText(campo, texto);
  await tester.pump();
}

/// Digita [texto] no `CurrencyField` do custo [nome] (ex: "Insumos").
Future<void> digitarCusto(
  WidgetTester tester,
  String nome,
  String texto,
) async {
  final campo = find.descendant(
    of: find.byKey(Key('custo-$nome')),
    matching: find.byType(TextField),
  );
  await tester.ensureVisible(campo);
  await tester.enterText(campo, texto);
  await tester.pump();
}

/// Preenche a etapa 1 com um cliente válido (CPF com dígitos corretos).
Future<void> preencherCliente(
  WidgetTester tester, {
  String nome = 'João da Silva',
  String cpf = '52998224725',
}) async {
  await digitar(tester, 'campo-nome', nome);
  await digitar(tester, 'campo-numero', '11987654321');
  await digitar(tester, 'campo-cpf-cnpj', cpf);
}

/// Escolhe [opcao] no "Tipo do serviço".
Future<void> escolherTipoServico(WidgetTester tester, String opcao) async {
  await tocar(tester, find.byType(DropdownButtonFormField<String>));
  await tester.tap(find.text(opcao).last);
  await tester.pumpAndSettle();
}

/// Botão "Continuar" do rodapé.
Finder get continuar => find.text('Continuar');
