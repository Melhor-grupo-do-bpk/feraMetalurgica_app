import 'package:fera_metalurgica_app/core/di/banco_de_dados.dart';
import 'package:fera_metalurgica_app/core/theme/app_theme.dart';
import 'package:fera_metalurgica_app/core/theme/tema_app.dart';
import 'package:fera_metalurgica_app/core/widgets/app_top_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../mocks/banco_de_teste.dart';

void main() {
  late Database banco;

  setUp(() async => banco = await bancoDeTeste());
  tearDown(() => banco.close());

  /// A barra num app que usa o tema de [temaAppProvider], como o `FeraApp`.
  Future<void> montar(WidgetTester tester, {VoidCallback? onBack}) =>
      tester.pumpWidget(
        ProviderScope(
          overrides: [
            bancoDeDadosProvider.overrideWithValue(banco),
            temaInicialProvider.overrideWithValue(ThemeMode.light),
          ],
          child: Consumer(
            builder: (context, ref, _) => MaterialApp(
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: ref.watch(temaAppProvider),
              home: Scaffold(appBar: AppTopBar(onBack: onBack)),
            ),
          ),
        ),
      );

  testWidgets('mostra o logo e a troca de tema; voltar só com onBack', (
    tester,
  ) async {
    await montar(tester);

    expect(find.bySemanticsLabel('FERA'), findsOneWidget);
    expect(find.byTooltip('Usar tema escuro'), findsOneWidget);
    expect(find.byTooltip('Voltar'), findsNothing);
  });

  testWidgets('aciona o callback de voltar', (tester) async {
    var voltou = false;
    await montar(tester, onBack: () => voltou = true);

    await tester.tap(find.byTooltip('Voltar'));

    expect(voltou, isTrue);
  });

  testWidgets('o botão alterna entre escuro e claro (D-45)', (tester) async {
    await montar(tester);

    await tester.tap(find.byTooltip('Usar tema escuro'));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(AppTopBar))).brightness,
      Brightness.dark,
    );
    expect(find.byTooltip('Usar tema claro'), findsOneWidget);

    await tester.tap(find.byTooltip('Usar tema claro'));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(AppTopBar))).brightness,
      Brightness.light,
    );
  });
}
