import 'package:fera_metalurgica_app/core/di/local_storage_provider.dart';
import 'package:fera_metalurgica_app/core/di/relogio_provider.dart';
import 'package:fera_metalurgica_app/core/router/app_router.dart';
import 'package:fera_metalurgica_app/core/widgets/stat_card.dart';
import 'package:fera_metalurgica_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../mocks/fake_local_json_storage.dart';

/// Critério de aceite da T7: uma tarefa criada no formulário aparece no
/// dia certo e, se for de produção, soma em "Pedidos em produção".
void main() {
  testWidgets('tarefa de produção criada aparece no dia e no dashboard', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(800, 3000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // Como `feraAppDeTeste()`, mas com o "agora" fixo no dia do Figma.
    final storage = InMemoryJsonStorage();
    await popularDadosIniciais(storage, incluirExemplos: true);
    appRouter.go(AppRoutes.dashboard);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localJsonStorageProvider.overrideWithValue(storage),
          agoraProvider.overrideWithValue(DateTime(2023, 10, 9, 8)),
        ],
        child: const FeraApp(),
      ),
    );
    await tester.pumpAndSettle();

    String producao() => tester
        .widget<StatCard>(find.widgetWithText(StatCard, 'Pedidos em produção'))
        .valor;
    final antes = producao();

    appRouter.go(AppRoutes.cronograma);
    await tester.pumpAndSettle();
    expect(find.text('0 tarefas'), findsNothing);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('tarefa-titulo')),
      'Soldar estrutura do pedido #00125',
    );
    await tester.tap(find.byKey(const ValueKey('tarefa-data')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('10'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('tarefa-hora')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('tarefa-tipo')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Produção').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar tarefa'));
    await tester.pumpAndSettle();

    // De volta ao cronograma: a tarefa entrou em "Amanhã" (10/10), antes
    // da tarefa das 14:00.
    expect(find.text('Soldar estrutura do pedido #00125'), findsOneWidget);
    expect(find.text('2 tarefas'), findsNWidgets(2));

    appRouter.go(AppRoutes.dashboard);
    await tester.pumpAndSettle();
    expect(int.parse(producao()), int.parse(antes) + 1);
  });
}
