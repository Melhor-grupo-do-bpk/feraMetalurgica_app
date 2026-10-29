import 'package:fera_metalurgica_app/core/widgets/form_campo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pump_themed.dart';

void main() {
  testWidgets('mostra o rótulo acima do campo', (tester) async {
    await pumpThemed(
      tester,
      const FormCampo(rotulo: 'Descrição', child: TextField()),
    );

    expect(find.text('Descrição'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Descrição')).dy,
      lessThan(tester.getTopLeft(find.byType(TextField)).dy),
    );
  });

  testWidgets('obrigatório acrescenta o "*"', (tester) async {
    await pumpThemed(
      tester,
      const FormCampo(rotulo: 'Título', obrigatorio: true, child: TextField()),
    );

    expect(find.text('Título *'), findsOneWidget);
  });
}
