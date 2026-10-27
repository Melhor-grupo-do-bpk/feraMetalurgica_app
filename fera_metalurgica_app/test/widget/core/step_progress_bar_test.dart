import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/widgets/step_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pump_themed.dart';

void main() {
  testWidgets('desenha 4 segmentos e preenche até a etapa atual', (
    tester,
  ) async {
    await pumpThemed(tester, const StepProgressBar(etapaAtual: 2));

    Color corDo(int i) {
      final box = tester.widget<DecoratedBox>(
        find.byKey(ValueKey('step-segment-$i')),
      );
      return (box.decoration as BoxDecoration).color!;
    }

    expect(find.byKey(const ValueKey('step-segment-3')), findsOneWidget);
    expect(find.byKey(const ValueKey('step-segment-4')), findsNothing);
    expect(corDo(0), AppColors.light.brand);
    expect(corDo(1), AppColors.light.brand);
    expect(corDo(2), AppColors.light.progressTrack);
    expect(corDo(3), AppColors.light.progressTrack);
  });

  testWidgets('os segmentos têm a altura da barra', (tester) async {
    await pumpThemed(tester, const StepProgressBar(etapaAtual: 1));

    for (var i = 0; i < 4; i++) {
      expect(
        tester.getSize(find.byKey(ValueKey('step-segment-$i'))).height,
        8,
      );
    }
  });
}
