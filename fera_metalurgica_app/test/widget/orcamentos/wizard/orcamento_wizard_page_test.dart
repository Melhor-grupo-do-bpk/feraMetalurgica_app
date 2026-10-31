import 'dart:async';

import 'package:fera_metalurgica_app/core/router/app_routes.dart';
import 'package:fera_metalurgica_app/features/orcamentos/orcamentos.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/previa/linha_valor.dart';
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

/// Unidade de trabalho que só grava depois de [liberar], para testar o
/// clique duplo durante a gravação. Conta as chamadas.
class _UnidadeLenta implements UnidadeDeTrabalho {
  _UnidadeLenta(this._real);

  final UnidadeDeTrabalho _real;
  final Completer<void> liberar = Completer<void>();
  int chamadas = 0;

  @override
  Future<T> executarEmTransacao<T>(
    Future<T> Function(RepositoriosTransacao repos) operacao,
  ) async {
    chamadas++;
    await liberar.future;
    return await _real.executarEmTransacao(operacao);
  }
}

/// Unidade de trabalho que falha na primeira gravação e grava nas
/// seguintes.
class _UnidadeQueFalhaUmaVez implements UnidadeDeTrabalho {
  _UnidadeQueFalhaUmaVez(this._real);

  final UnidadeDeTrabalho _real;
  bool _falhou = false;

  @override
  Future<T> executarEmTransacao<T>(
    Future<T> Function(RepositoriosTransacao repos) operacao,
  ) async {
    if (!_falhou) {
      _falhou = true;
      throw StateError('disco cheio');
    }
    return await _real.executarEmTransacao(operacao);
  }
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

  /// Abre [rota] com `abrirWizard`, com os [extras] somados aos overrides.
  Future<GoRouter> abrir(
    WidgetTester tester,
    String rota, {
    ThemeMode themeMode = ThemeMode.light,
    List<Override> extras = const [],
  }) => abrirWizard(
    tester,
    rota,
    overrides: [...overrides, ...extras],
    themeMode: themeMode,
  );

  for (final modo in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('etapa 1 renderiza (${modo.name})', (tester) async {
      await abrir(tester, AppRoutes.novoOrcamento(), themeMode: modo);

      expect(find.text('Novo Orçamento'), findsOneWidget);
      expect(find.text('Etapa 1 de 4: Cliente'), findsOneWidget);
      expect(find.byKey(const ValueKey('wizard-busca-cliente')), findsOne);
      expect(find.text('Dados do cliente'.toUpperCase()), findsOneWidget);
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
    expect(find.byType(PreviaOrcamento), findsOneWidget);
    expect(
      find.widgetWithText(LinhaValor, r'R$ 1.098,00'),
      // O produto, o total dos produtos, o subtotal e o total geral.
      findsNWidgets(4),
    );

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

  /// A unidade de trabalho real, sobre o banco dos [overrides].
  UnidadeDeTrabalho unidadeReal() {
    final container = ProviderContainer(overrides: overrides);
    addTearDown(container.dispose);
    return container.read(unidadeDeTrabalhoProvider);
  }

  testWidgets('clique duplo em "Finalizar" grava um orçamento só', (
    tester,
  ) async {
    final lenta = _UnidadeLenta(unidadeReal());
    await abrir(
      tester,
      AppRoutes.novoOrcamento(),
      extras: [unidadeDeTrabalhoProvider.overrideWithValue(lenta)],
    );
    await preencherStub(tester);

    await tester.tap(find.text('Finalizar'));
    await tester.pump();
    // Gravando: botão bloqueado, com o progresso.
    expect(find.text('Salvando...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.text('Salvando...'), warnIfMissed: false);
    await tester.pump();
    // Voltar também fica bloqueado durante a gravação.
    await tester.tap(find.text('Voltar'), warnIfMissed: false);
    await tester.pump();
    expect(find.text('Etapa 4 de 4: Prévia'), findsOneWidget);

    lenta.liberar.complete();
    await tester.pumpAndSettle();

    expect(lenta.chamadas, 1);
    final gravados = await orcamentosGravados(overrides);
    expect(gravados, hasLength(exemplos.length + 1));
    expect(find.text('detalhes ${gravados.first.id}'), findsOneWidget);
  });

  testWidgets('depois de uma falha, tentar de novo grava', (tester) async {
    await abrir(
      tester,
      AppRoutes.novoOrcamento(),
      extras: [
        unidadeDeTrabalhoProvider.overrideWithValue(
          _UnidadeQueFalhaUmaVez(unidadeReal()),
        ),
      ],
    );
    await preencherStub(tester);

    await tocar(tester, find.text('Finalizar'));
    expect(
      find.text('Não foi possível salvar o orçamento. Tente novamente.'),
      findsOneWidget,
    );
    expect(await orcamentosGravados(overrides), hasLength(exemplos.length));

    await tocar(tester, find.text('Finalizar'));

    final gravados = await orcamentosGravados(overrides);
    expect(gravados, hasLength(exemplos.length + 1));
    expect(gravados.first.codigo, '261026-01');
    expect(find.text('detalhes ${gravados.first.id}'), findsOneWidget);
  });

  testWidgets('voltar do sistema na etapa 1 também pede o descarte', (
    tester,
  ) async {
    await abrir(tester, AppRoutes.novoOrcamento());

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Descartar orçamento?'), findsOneWidget);
  });

  for (final modo in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('diálogo de descarte em 360 dp (${modo.name})', (tester) async {
      final semantics = tester.ensureSemantics();
      await abrir(tester, AppRoutes.novoOrcamento(), themeMode: modo);
      tester.view.physicalSize = const Size(360, 640);
      await tester.pumpAndSettle();

      await tocar(tester, find.byIcon(Icons.arrow_back));

      expect(find.text('Descartar orçamento?'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      semantics.dispose();
    });
  }

  group('edição (D-30)', () {
    testWidgets('salvar grava a rev. 2 e volta aos detalhes', (tester) async {
      final c = exemplos.last;
      expect(c.codigo, '241026-01');
      await abrir(tester, AppRoutes.editarOrcamento(c.id));

      expect(find.text('Editar Orçamento'), findsOneWidget);
      await tocar(tester, continuar);
      await tocar(tester, continuar);
      await tocar(tester, continuar);
      expect(find.text('Nº 241026-01 rev. 2'), findsOneWidget);

      await tocar(tester, find.text('Salvar alterações'));

      final revisado = (await orcamentosGravados(overrides)).first;
      expect(revisado.id, c.id);
      expect(revisado.codigoExibicao, '241026-01 rev. 2');
      expect(revisado.atualizadoEm, agora);
      expect(revisado.totais, c.totais);
      expect(find.text('detalhes ${c.id}'), findsOneWidget);
    });

    testWidgets('sair pede para descartar as alterações', (tester) async {
      await abrir(tester, AppRoutes.editarOrcamento(exemplos.last.id));

      await tocar(tester, find.byIcon(Icons.arrow_back));

      expect(find.text('Descartar alterações?'), findsOneWidget);
      expect(find.textContaining('O orçamento salvo não muda.'), findsOne);
      await tocar(tester, find.text('Descartar'));
      expect(find.text('detalhes ${exemplos.last.id}'), findsOneWidget);
    });

    testWidgets('orçamento inexistente mostra o erro e volta', (tester) async {
      await abrir(tester, AppRoutes.editarOrcamento('nao-existe'));

      expect(find.text('Não foi possível abrir o orçamento.'), findsOneWidget);
      await tocar(tester, find.text('Voltar'));
      expect(find.text('detalhes nao-existe'), findsOneWidget);
    });
  });
}
