import 'dart:async';

import 'package:fera_metalurgica_app/core/router/app_routes.dart';
import 'package:fera_metalurgica_app/core/theme/app_theme.dart';
import 'package:fera_metalurgica_app/features/orcamentos/orcamentos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../core/teste_helpers.dart';

export '../../core/teste_helpers.dart' show tocar;

/// Botão "Continuar" do rodapé.
Finder get continuar => find.text('Continuar');

/// Abre [rota] (o wizard novo ou a edição) num router mínimo: a lista e os
/// detalhes viram os textos "lista" e "detalhes" seguido do id, e o wizard
/// é a tela real. Empilha as telas como o app (lista, detalhes na edição,
/// wizard), para o voltar ter para onde ir. Devolve o router, para
/// conferir a navegação.
Future<GoRouter> abrirWizard(
  WidgetTester tester,
  String rota, {
  required List<Override> overrides,
  ThemeMode themeMode = ThemeMode.light,
  Size tamanho = const Size(800, 2400),
}) async {
  tester.view
    ..physicalSize = tamanho
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final router = GoRouter(
    initialLocation: AppRoutes.orcamentos,
    routes: [
      GoRoute(
        path: AppRoutes.orcamentos,
        builder: (_, _) => const Text('lista'),
        routes: [
          GoRoute(path: 'novo', builder: (_, _) => const OrcamentoWizardPage()),
          GoRoute(
            path: ':id',
            builder: (_, state) =>
                Text('detalhes ${state.pathParameters['id']}'),
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
    ProviderScope(
      overrides: overrides,
      child: MaterialApp.router(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  // `push` só completa quando a rota sai da pilha: não espere.
  const sufixoEdicao = '/editar';
  if (rota.endsWith(sufixoEdicao)) {
    unawaited(
      router.push(rota.substring(0, rota.length - sufixoEdicao.length)),
    );
    await tester.pumpAndSettle();
  }
  unawaited(router.push(rota));
  await tester.pumpAndSettle();
  return router;
}

/// Passa pelas 4 etapas do wizard com um orçamento simples: escolhe
/// [cliente] na busca, monta o "Produto de teste" na etapa 2, avança pelos
/// valores e chega à prévia.
Future<void> preencherStub(
  WidgetTester tester, {
  String cliente = 'João da Silva',
}) async {
  await tester.enterText(
    find.byKey(const ValueKey('wizard-busca-cliente')),
    cliente,
  );
  await tester.pumpAndSettle();
  await tocar(
    tester,
    find.descendant(
      of: find.byKey(const ValueKey('wizard-resultados-cliente')),
      matching: find.text(cliente),
    ),
  );
  await tocar(tester, continuar);
  // Etapa 2 (V2-A): 3 produtos, base R$ 150,00, uma peça de 120 × 60 cm
  // em granito (R$ 300,00/m²): R$ 366,00 por produto, R$ 1.098,00 no item.
  await tocar(tester, find.text('Adicionar produto'));
  for (final (chave, texto) in [
    ('produto-descricao', 'Produto de teste'),
    ('produto-quantidade', '3'),
    ('produto-preco-base', '150,00'),
    ('peca-descricao', 'Placa'),
  ]) {
    await tester.enterText(find.byKey(ValueKey(chave)), texto);
  }
  await tocar(tester, find.byKey(const ValueKey('peca-material')));
  await tocar(tester, find.text('Granito - variedade B - 2 cm'));
  await tester.enterText(find.byKey(const ValueKey('peca-comprimento')), '120');
  await tester.enterText(find.byKey(const ValueKey('peca-largura')), '60');
  await tocar(tester, find.text('Adicionar peça'));
  await tocar(tester, find.text('Adicionar produto'));
  await tocar(tester, continuar);
  await tocar(tester, continuar);
}
