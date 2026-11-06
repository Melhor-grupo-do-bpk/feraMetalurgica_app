import 'package:fera_metalurgica_app/core/domain/dinheiro.dart';
import 'package:fera_metalurgica_app/core/widgets/campo_dinheiro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pump_themed.dart';

void main() {
  Future<List<Dinheiro?>> montar(
    WidgetTester tester, {
    Dinheiro? valorInicial,
    String? errorText,
  }) async {
    final lidos = <Dinheiro?>[];
    await pumpThemed(
      tester,
      Form(
        child: CampoDinheiro(
          rotulo: 'Insumos',
          valorInicial: valorInicial,
          errorText: errorText,
          onChanged: lidos.add,
        ),
      ),
    );
    return lidos;
  }

  testWidgets('mostra o valor inicial formatado', (tester) async {
    await montar(tester, valorInicial: const Dinheiro(123456));

    expect(find.text('1.234,56'), findsOneWidget);
    expect(find.text('Insumos'), findsOneWidget);
  });

  testWidgets('aplica a máscara: os dígitos entram como centavos', (
    tester,
  ) async {
    final lidos = await montar(tester);

    await tester.enterText(find.byType(TextFormField), '123456');

    expect(find.text('1.234,56'), findsOneWidget);
    expect(lidos, [const Dinheiro(123456)]);
  });

  testWidgets('lê texto pt-BR em centavos, sem double', (tester) async {
    final lidos = await montar(tester);

    await tester.enterText(find.byType(TextFormField), '1.234,56');

    expect(lidos, [const Dinheiro(123456)]);
  });

  testWidgets('campo vazio devolve null', (tester) async {
    final lidos = await montar(tester, valorInicial: const Dinheiro(100));

    await tester.enterText(find.byType(TextFormField), '');

    expect(lidos, [null]);
  });

  testWidgets('mostra o erro de regra vindo de fora', (tester) async {
    await montar(tester, errorText: 'Maior que o subtotal');

    expect(find.text('Maior que o subtotal'), findsOneWidget);
  });
}
