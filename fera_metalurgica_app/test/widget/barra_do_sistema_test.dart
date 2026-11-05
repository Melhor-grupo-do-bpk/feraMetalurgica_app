import 'package:fera_metalurgica_app/core/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fera_app_de_teste.dart';

/// No Android recente o app é desenhado por baixo da barra de navegação do
/// sistema: as telas têm de terminar acima dela.
void main() {
  const alturaDaBarra = 48.0;

  testWidgets('as telas terminam acima da barra do sistema', (tester) async {
    tester.view
      ..physicalSize = const Size(360, 800)
      ..devicePixelRatio = 1
      ..padding = const FakeViewPadding(bottom: alturaDaBarra)
      ..viewPadding = const FakeViewPadding(bottom: alturaDaBarra);
    addTearDown(tester.view.reset);

    appRouter.go(AppRoutes.material());
    await tester.pumpWidget(await feraAppDeTeste());
    await tester.pumpAndSettle();

    expect(
      tester.getBottomLeft(find.byType(Scaffold).last).dy,
      800 - alturaDaBarra,
    );
    final estilo = tester
        .widget<AnnotatedRegion<SystemUiOverlayStyle>>(
          find.byWidgetPredicate(
            (w) =>
                w is AnnotatedRegion<SystemUiOverlayStyle> &&
                w.value.systemNavigationBarContrastEnforced == false,
          ),
        )
        .value;
    expect(estilo.systemNavigationBarColor, isNotNull);
  });
}
