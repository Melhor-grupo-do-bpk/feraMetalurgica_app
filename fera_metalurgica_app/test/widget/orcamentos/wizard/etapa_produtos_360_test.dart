import 'package:fera_metalurgica_app/core/router/app_routes.dart';
import 'package:fera_metalurgica_app/core/theme/app_theme.dart';
import 'package:fera_metalurgica_app/features/orcamentos/orcamentos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../mocks/container_de_teste.dart';
import 'wizard_teste_helpers.dart';

/// Etapa 2 a 360 dp, nos modos claro e escuro, dentro da página real do
/// wizard (editando o exemplo C, que já tem 2 produtos): sem transbordar,
/// com as diretrizes de acessibilidade, e o formulário inline usável até
/// adicionar um produto.
void main() {
  for (final tema in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('etapa 2 em 360 dp, ${tema.name}', (tester) async {
      final semantics = tester.ensureSemantics();
      tester.view
        ..physicalSize = const Size(360, 640)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final overrides = await overridesDeTeste(
        agora: DateTime(2026, 10, 26, 10),
      );
      final [_, c] = await orcamentosGravados(overrides);
      final container = ProviderContainer(overrides: overrides);
      addTearDown(container.dispose);
      final router = GoRouter(
        initialLocation: AppRoutes.editarOrcamento(c.id),
        routes: [
          GoRoute(
            path: AppRoutes.orcamentos,
            builder: (_, _) => const Text('lista'),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, _) => const Text('detalhes'),
                routes: [
                  GoRoute(
                    path: 'editar',
                    builder: (_, state) => OrcamentoWizardPage(
                      orcamentoId: state.pathParameters['id'],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: tema,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      Future<void> conferir() async {
        expect(tester.takeException(), isNull);
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      }

      Future<void> escrever(String chave, String texto) async {
        final campo = find.byKey(ValueKey(chave));
        await tester.ensureVisible(campo);
        await tester.pumpAndSettle();
        await tester.enterText(campo, texto);
        await tester.pumpAndSettle();
      }

      await tocar(tester, continuar);
      expect(find.text('Etapa 2 de 4: Produtos'), findsOneWidget);
      await conferir();

      await tocar(tester, find.text('Novo produto'));
      await escrever('produto-descricao', 'Painel em MDF');
      await escrever('produto-quantidade', '3');
      await escrever('produto-preco-base', '150,00');
      await escrever('peca-descricao', 'Painel');
      await tocar(tester, find.byKey(const ValueKey('peca-material')));
      // O seletor de material, aberto.
      await conferir();
      await tocar(
        tester,
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('MDF 15 mm'),
        ),
      );
      await escrever('peca-comprimento', '120');
      await escrever('peca-largura', '60');
      await conferir();

      await tocar(tester, find.text('Adicionar peça'));
      await tocar(tester, find.text('Adicionar produto'));
      await conferir();

      final itens = container.read(orcamentoControllerProvider).edicao!.itens;
      expect(itens, hasLength(3));
      expect(itens.last.descricao, 'Painel em MDF');
      semantics.dispose();
    });
  }
}
