import 'dart:async';

import 'package:fera_metalurgica_app/core/router/app_routes.dart';
import 'package:fera_metalurgica_app/core/theme/app_theme.dart';
import 'package:fera_metalurgica_app/features/orcamentos/orcamentos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../mocks/container_de_teste.dart';
import 'wizard_teste_helpers.dart';

/// Unidade de trabalho que sempre falha, para simular erro de gravação.
class _UnidadeQueFalha implements UnidadeDeTrabalho {
  @override
  Future<T> executarEmTransacao<T>(
    Future<T> Function(RepositoriosTransacao repos) operacao,
  ) async => throw StateError('disco cheio');
}

/// Wizard em stub da F2 sobre os dados de exemplo (empresa, materiais,
/// clientes e os orçamentos C de 24/10 e B de 25/10/2026). "Agora" é
/// 26/10/2026, 10h.
void main() {
  final agora = DateTime(2026, 10, 26, 10);
  late List<Override> overrides;
  late List<Orcamento> exemplos;

  setUp(() async {
    overrides = await overridesDeTeste(agora: agora);
    exemplos = await orcamentosGravados(overrides);
  });

  /// Abre [rota] num router mínimo: a lista e os detalhes viram textos, e
  /// o wizard é a tela real.
  Future<GoRouter> abrir(
    WidgetTester tester,
    String rota, {
    ThemeMode themeMode = ThemeMode.light,
    List<Override> extras = const [],
  }) async {
    tester.view
      ..physicalSize = const Size(800, 2400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: AppRoutes.orcamentos,
      routes: [
        GoRoute(
          path: AppRoutes.orcamentos,
          builder: (_, _) => const Text('lista'),
          routes: [
            GoRoute(
              path: 'novo',
              builder: (_, _) => const OrcamentoWizardPage(),
            ),
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
        overrides: [...overrides, ...extras],
        child: MaterialApp.router(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Empilha sobre a lista (e os detalhes, na edição), como o app faz,
    // para o voltar ter para onde ir. `push` só completa quando a rota sai
    // da pilha: não espere.
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

  for (final modo in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('etapa 1 renderiza (${modo.name})', (tester) async {
      await abrir(tester, AppRoutes.novoOrcamento(), themeMode: modo);

      expect(find.text('Novo Orçamento'), findsOneWidget);
      expect(find.text('Etapa 1 de 4: Cliente'), findsOneWidget);
      expect(find.text('João da Silva'), findsOneWidget);
      expect(find.text('Voltar'), findsNothing);
    });
  }

  testWidgets('sem cliente, não avança e avisa', (tester) async {
    await abrir(tester, AppRoutes.novoOrcamento());

    await tocar(tester, continuar);

    expect(find.text('Etapa 1 de 4: Cliente'), findsOneWidget);
    expect(find.text('Informe o cliente'), findsOneWidget);
  });

  testWidgets('cria um orçamento novo com o código do dia (-01)', (
    tester,
  ) async {
    await abrir(tester, AppRoutes.novoOrcamento());

    await preencherStub(tester);
    // Granito (o primeiro ativo) a R$ 300,00/m²: 0,72 m² → R$ 216,00 +
    // R$ 150,00 de base = R$ 366,00 por produto, 3 produtos.
    expect(find.text('Etapa 4 de 4: Prévia'), findsOneWidget);
    expect(find.text(r'Total geral: R$ 1.098,00'), findsOneWidget);

    await tocar(tester, find.text('Finalizar'));

    final novo = (await orcamentosGravados(overrides)).first;
    expect(novo.codigo, '261026-01');
    expect(novo.cliente.nome, 'João da Silva');
    expect(find.text('detalhes ${novo.id}'), findsOneWidget);
  });

  testWidgets('voltar entre etapas não perde dados', (tester) async {
    await abrir(tester, AppRoutes.novoOrcamento());
    await preencherStub(tester);

    await tocar(tester, find.text('Voltar'));
    await tocar(tester, find.text('Voltar'));

    expect(find.text('Etapa 2 de 4: Produtos'), findsOneWidget);
    expect(find.text('Produto de teste'), findsOneWidget);
  });

  testWidgets('sair na etapa 1 pede confirmação de descarte', (tester) async {
    await abrir(tester, AppRoutes.novoOrcamento());

    await tocar(tester, find.byIcon(Icons.arrow_back));
    expect(find.text('Descartar orçamento?'), findsOneWidget);
    await tocar(tester, find.text('Cancelar'));
    expect(find.text('Novo Orçamento'), findsOneWidget);

    await tocar(tester, find.byIcon(Icons.arrow_back));
    await tocar(tester, find.text('Descartar'));
    expect(find.text('lista'), findsOneWidget);
  });

  testWidgets('falha de gravação avisa e mantém a sessão', (tester) async {
    await abrir(
      tester,
      AppRoutes.novoOrcamento(),
      extras: [unidadeDeTrabalhoProvider.overrideWithValue(_UnidadeQueFalha())],
    );
    await preencherStub(tester);

    await tocar(tester, find.text('Finalizar'));

    expect(
      find.text('Não foi possível salvar o orçamento. Tente novamente.'),
      findsOneWidget,
    );
    expect(find.text('Etapa 4 de 4: Prévia'), findsOneWidget);
    expect(find.text('Finalizar'), findsOneWidget);
  });

  group('edição (D-30)', () {
    testWidgets('salvar grava a rev. 2 e volta aos detalhes', (tester) async {
      final c = exemplos.last;
      expect(c.codigo, '241026-01');
      await abrir(tester, AppRoutes.editarOrcamento(c.id));

      expect(find.text('Editar Orçamento'), findsOneWidget);
      await tocar(tester, continuar);
      await tocar(tester, continuar);
      await tocar(tester, continuar);
      expect(find.text('Orçamento 241026-01 rev. 2'), findsOneWidget);

      await tocar(tester, find.text('Salvar alterações'));

      final revisado = (await orcamentosGravados(overrides)).first;
      expect(revisado.id, c.id);
      expect(revisado.codigoExibicao, '241026-01 rev. 2');
      expect(revisado.atualizadoEm, agora);
      expect(revisado.totais, c.totais);
      expect(find.text('detalhes ${c.id}'), findsOneWidget);
    });

    testWidgets('orçamento inexistente mostra o erro e volta', (tester) async {
      await abrir(tester, AppRoutes.editarOrcamento('nao-existe'));

      expect(find.text('Não foi possível abrir o orçamento.'), findsOneWidget);
      await tocar(tester, find.text('Voltar'));
      expect(find.text('detalhes nao-existe'), findsOneWidget);
    });
  });
}
