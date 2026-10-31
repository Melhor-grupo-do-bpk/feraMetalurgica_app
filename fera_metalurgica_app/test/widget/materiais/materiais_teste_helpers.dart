import 'package:fera_metalurgica_app/core/router/app_router.dart';
import 'package:fera_metalurgica_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../mocks/container_de_teste.dart';

/// Abre o app em [rota], com os [overrides] dados ou os dados de exemplo
/// (`overridesDeTeste`), em [tamanho] e [themeMode].
Future<void> abrirEm(
  WidgetTester tester,
  String rota, {
  List<Override>? overrides,
  ThemeMode themeMode = ThemeMode.light,
  Size tamanho = const Size(412, 915),
}) async {
  tester.view
    ..physicalSize = tamanho
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final efetivos = overrides ?? await overridesDeTeste();
  appRouter.go(rota);
  await tester.pumpWidget(
    ProviderScope(
      overrides: efetivos,
      child: FeraApp(themeMode: themeMode),
    ),
  );
  await tester.pumpAndSettle();
}

/// O [ProviderContainer] do app montado.
ProviderContainer containerDoApp(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(FeraApp)));

/// Rola até [finder], toca e espera assentar.
Future<void> tocar(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Digita [texto] no campo de texto dentro de [campo] (que pode ser o
/// próprio `TextField` ou um widget que o contém).
Future<void> digitar(WidgetTester tester, Finder campo, String texto) async {
  final editavel = find.descendant(
    of: campo,
    matching: find.byType(EditableText),
  );
  await tester.ensureVisible(editavel);
  await tester.enterText(editavel, texto);
  await tester.pumpAndSettle();
}

/// Confere as diretrizes de contraste e de área de toque do Flutter na
/// tela atual (RNF-06).
Future<void> conferirAcessibilidade(WidgetTester tester) async {
  expect(tester.takeException(), isNull);
  await expectLater(tester, meetsGuideline(textContrastGuideline));
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
}
