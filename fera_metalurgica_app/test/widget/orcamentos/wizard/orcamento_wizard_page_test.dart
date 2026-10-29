import 'dart:async';

import 'package:fera_metalurgica_app/core/di/local_storage_provider.dart';
import 'package:fera_metalurgica_app/core/di/relogio_provider.dart';
import 'package:fera_metalurgica_app/core/router/app_routes.dart';
import 'package:fera_metalurgica_app/core/theme/app_theme.dart';
import 'package:fera_metalurgica_app/core/widgets/item_card.dart';
import 'package:fera_metalurgica_app/features/orcamentos/orcamentos.dart';
import 'package:fera_metalurgica_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../mocks/fake_local_json_storage.dart';
import 'wizard_teste_helpers.dart';

void main() {
  late InMemoryJsonStorage storage;

  setUp(() async {
    storage = InMemoryJsonStorage();
    await popularDadosIniciais(storage, incluirExemplos: true);
  });

  /// Abre [rota] num router mínimo: a lista e os detalhes viram textos, e
  /// o wizard é a tela real, sobre dados semeados em memória.
  Future<GoRouter> abrir(
    WidgetTester tester,
    String rota, {
    ThemeMode themeMode = ThemeMode.light,
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
              builder: (_, state) => OrcamentoWizardPage(
                produtoId: state.uri.queryParameters['produtoId'],
              ),
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
        overrides: [
          localJsonStorageProvider.overrideWithValue(storage),
          agoraProvider.overrideWithValue(DateTime(2026, 10, 26)),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Empilha sobre a lista, como o app faz, para o voltar ter para onde ir.
    // `push` só completa quando a rota sai da pilha: não espere.
    for (final parte in _empilhar(rota)) {
      unawaited(router.push(parte));
      await tester.pumpAndSettle();
    }
    await tester.pumpAndSettle();
    return router;
  }

  for (final modo in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('etapa 1 renderiza (${modo.name})', (tester) async {
      await abrir(tester, AppRoutes.novoOrcamento(), themeMode: modo);

      expect(find.text('Novo Orçamento'), findsOneWidget);
      expect(find.text('Etapa 1 de 4: Dados do cliente'), findsOneWidget);
      expect(find.text('CPF/CNPJ do cliente *'), findsOneWidget);
      expect(find.text('Voltar'), findsNothing);
    });
  }

  testWidgets('etapa 1 bloqueia o avanço com CPF inválido', (tester) async {
    await abrir(tester, AppRoutes.novoOrcamento());

    await preencherCliente(tester, cpf: '12345678900');
    await tocar(tester, continuar);

    expect(find.text('Etapa 1 de 4: Dados do cliente'), findsOneWidget);
    expect(find.text('CPF inválido'), findsOneWidget);

    await digitar(tester, 'campo-cpf-cnpj', '52998224725');
    await tocar(tester, continuar);

    expect(find.text('Etapa 2 de 4: Detalhes do item(s)'), findsOneWidget);
  });

  testWidgets('voltar mantém o que foi digitado', (tester) async {
    await abrir(tester, AppRoutes.novoOrcamento());
    await preencherCliente(tester);
    await tocar(tester, continuar);

    await tocar(tester, find.text('Voltar'));

    expect(find.text('Etapa 1 de 4: Dados do cliente'), findsOneWidget);
    expect(find.text('João da Silva'), findsOneWidget);
    expect(find.text('529.982.247-25'), findsOneWidget);
  });

  testWidgets('etapa 2 exige pelo menos 1 item', (tester) async {
    await abrir(tester, AppRoutes.novoOrcamento());
    await preencherCliente(tester);
    await tocar(tester, continuar);

    await tocar(tester, continuar);

    expect(find.text('Adicione pelo menos 1 item.'), findsOneWidget);
    expect(find.text('Etapa 2 de 4: Detalhes do item(s)'), findsOneWidget);
  });

  testWidgets('etapa 2 adiciona, edita e exclui itens', (tester) async {
    await abrir(tester, AppRoutes.novoOrcamento());
    await preencherCliente(tester);
    await tocar(tester, continuar);

    await escolherTipoServico(tester, 'Outro');
    await digitar(tester, 'campo-outro-servico', 'Escada metálica');
    await digitar(tester, 'campo-medida-A', '2,5');
    await digitar(tester, 'campo-medida-L', '1.2');
    await digitar(tester, 'campo-material', 'Aço Carbono');
    await tocar(tester, find.text('Adicionar Item'));

    expect(find.text('Itens Adicionados (1)'), findsOneWidget);
    expect(find.text('Escada metálica'), findsOneWidget);
    expect(find.text('2.50m x 1.20m'), findsOneWidget);
    expect(find.text('Qtd: 1 un'), findsOneWidget);

    await tocar(tester, find.byTooltip('Editar'));
    expect(find.text('Salvar Item'), findsOneWidget);
    await digitar(tester, 'campo-quantidade', '3');
    await tocar(tester, find.text('Salvar Item'));

    expect(find.text('Qtd: 3 un'), findsOneWidget);
    expect(find.text('Adicionar Item'), findsOneWidget);

    await tocar(tester, find.byTooltip('Excluir'));
    expect(find.text('Excluir item?'), findsOneWidget);
    await tocar(tester, find.text('Excluir'));

    expect(find.byType(ItemCard), findsNothing);
  });

  testWidgets('medida inválida mostra erro no campo', (tester) async {
    await abrir(tester, AppRoutes.novoOrcamento());
    await preencherCliente(tester);
    await tocar(tester, continuar);

    await escolherTipoServico(tester, 'Portão Basculante');
    await digitar(tester, 'campo-medida-A', '2,5,1');
    await tocar(tester, find.text('Adicionar Item'));

    expect(find.text('Inválida'), findsOneWidget);
    expect(find.byType(ItemCard), findsNothing);
  });

  testWidgets('vindo do catálogo, já começa com o produto (RF-27)', (
    tester,
  ) async {
    await abrir(
      tester,
      AppRoutes.novoOrcamento(produtoId: 'produto-portao-basculante'),
    );
    await preencherCliente(tester);
    await tocar(tester, continuar);

    expect(find.text('Itens Adicionados (1)'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ItemCard),
        matching: find.text('Portão Basculante'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('etapa 3 atualiza o total ao digitar', (tester) async {
    await abrir(
      tester,
      AppRoutes.novoOrcamento(produtoId: 'produto-portao-basculante'),
    );
    await preencherCliente(tester);
    await tocar(tester, continuar);
    await tocar(tester, continuar);
    expect(find.text('Etapa 3 de 4: Custos Operacionais'), findsOneWidget);

    Text total() =>
        tester.widget<Text>(find.byKey(const Key('total-previsto')));
    expect(total().data, r'R$ 0,00');

    await digitarCusto(tester, 'Matéria-prima', '245000');
    expect(total().data, r'R$ 2.450,00');

    await digitarCusto(tester, 'Mão de obra', '180000');
    expect(total().data, r'R$ 4.250,00');
  });

  group('sair do wizard (D-07)', () {
    testWidgets('sem alterações, sai direto', (tester) async {
      await abrir(tester, AppRoutes.novoOrcamento());

      await tocar(tester, find.byTooltip('Voltar'));

      expect(find.text('lista'), findsOneWidget);
    });

    testWidgets('com alterações, pede confirmação', (tester) async {
      await abrir(tester, AppRoutes.novoOrcamento());
      await digitar(tester, 'campo-nome', 'João');

      await tocar(tester, find.byTooltip('Voltar'));
      expect(find.text('Descartar orçamento?'), findsOneWidget);
      await tocar(tester, find.text('Cancelar'));
      expect(find.text('João'), findsOneWidget);

      await tocar(tester, find.byTooltip('Voltar'));
      await tocar(tester, find.text('Descartar'));
      expect(find.text('lista'), findsOneWidget);
    });

    testWidgets('voltar do sistema volta uma etapa', (tester) async {
      await abrir(tester, AppRoutes.novoOrcamento());
      await preencherCliente(tester);
      await tocar(tester, continuar);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('Etapa 1 de 4: Dados do cliente'), findsOneWidget);
    });
  });

  group('edição', () {
    testWidgets('carrega os dados e volta aos detalhes ao concluir', (
      tester,
    ) async {
      await abrir(tester, AppRoutes.editarOrcamento('00478'));

      expect(find.text('Editar Orçamento'), findsOneWidget);
      expect(find.text('Maria Souza'), findsOneWidget);

      await digitar(tester, 'campo-nome', 'Maria Souza Lima');
      for (var i = 0; i < 3; i++) {
        await tocar(tester, continuar);
      }
      await tocar(tester, continuar);

      expect(find.text('detalhes 00478'), findsOneWidget);
      final salvo = (await LocalOrcamentoRepository(
        storage,
      ).getAll()).firstWhere((o) => o.id == '00478');
      expect(salvo.cliente.nome, 'Maria Souza Lima');
      expect(salvo.status, StatusOrcamento.recusado);
    });

    testWidgets('orçamento inexistente mostra "não encontrado"', (
      tester,
    ) async {
      await abrir(tester, AppRoutes.editarOrcamento('99999'));

      expect(find.text('Orçamento não encontrado'), findsOneWidget);
    });
  });
}

/// Rotas a empilhar até [rota], a partir da lista (ex: a edição empilha os
/// detalhes e depois o wizard).
List<String> _empilhar(String rota) {
  final caminho = Uri.parse(rota).path;
  if (caminho.endsWith('/editar')) {
    return [caminho.substring(0, caminho.length - '/editar'.length), rota];
  }
  return [rota];
}
