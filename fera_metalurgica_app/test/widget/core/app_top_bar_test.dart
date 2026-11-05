import 'package:fera_metalurgica_app/core/widgets/app_top_bar.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pump_themed.dart';

void main() {
  testWidgets('mostra o logo, sem sino; voltar só aparece com onBack', (
    tester,
  ) async {
    await pumpThemed(tester, const AppTopBar());

    expect(find.bySemanticsLabel('FERA'), findsOneWidget);
    expect(find.byTooltip('Notificações'), findsNothing);
    expect(find.byTooltip('Voltar'), findsNothing);
  });

  testWidgets('aciona o callback de voltar', (tester) async {
    var voltou = false;
    await pumpThemed(tester, AppTopBar(onBack: () => voltou = true));

    await tester.tap(find.byTooltip('Voltar'));

    expect(voltou, isTrue);
  });
}
