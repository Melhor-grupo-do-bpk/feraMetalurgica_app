import 'package:fera_metalurgica_app/core/domain/dinheiro.dart';
import 'package:fera_metalurgica_app/core/domain/medida_cm.dart';
import 'package:fera_metalurgica_app/core/router/app_routes.dart';
import 'package:fera_metalurgica_app/core/theme/app_theme.dart';
import 'package:fera_metalurgica_app/features/materiais/materiais.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/calculadora_orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/item_orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/aviso_inline.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/etapa_produtos.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/orcamento_controller.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/produto/linha_resumo.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/produto/rascunho_produto.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/produto/sair_etapa_produtos.dart';
import 'package:flutter/material.dart' hide Material;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../mocks/container_de_teste.dart';
import 'wizard_teste_helpers.dart';

const String _granito = 'Granito - variedade B - 2 cm';
const String _madeira = 'Madeira - espécie A';
const String _mdf = 'MDF 15 mm';

/// Material salvo pela tela falsa de cadastro.
const Material _inox = Material(
  id: 'material-inox',
  nome: 'Aço inox',
  unidade: UnidadeCobranca.m2,
  precoReferencia: Dinheiro(12000),
);

/// Uma peça a preencher pela interface.
typedef _Peca = ({
  String descricao,
  String material,
  String comprimento,
  String largura,
  String? espessura,
  String quantidade,
  String? preco,
});

_Peca _peca(
  String descricao,
  String material,
  String comprimento,
  String largura, {
  String? espessura,
  String quantidade = '1',
  String? preco,
}) => (
  descricao: descricao,
  material: material,
  comprimento: comprimento,
  largura: largura,
  espessura: espessura,
  quantidade: quantidade,
  preco: preco,
);

/// Botão [texto] do diálogo aberto.
Finder _noDialogo(String texto) =>
    find.descendant(of: find.byType(AlertDialog), matching: find.text(texto));

/// Etapa 2 (V2-A) sobre a sessão de um orçamento novo, com os dados de
/// exemplo (granito R$ 300,00/m², madeira R$ 3.500,00/m³ e MDF
/// R$ 90,00/m²). Os números esperados são os do prompt §9.
void main() {
  late ProviderContainer container;

  setUp(() async {
    // O controller é autoDispose: o teste o mantém vivo.
    container = await containerDeTeste(agora: DateTime(2026, 10, 26, 10))
      ..listen(orcamentoControllerProvider, (_, _) {});
    await container.read(orcamentoControllerProvider.notifier).iniciar();
  });

  List<ItemOrcamento> itens() =>
      container.read(orcamentoControllerProvider).edicao!.itens;

  /// A etapa numa tela com scroll, como no wizard, e uma tela falsa de
  /// cadastro de material no caminho de `AppRoutes.material()`.
  Future<void> abrir(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(800, 2400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(
            body: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: EtapaProdutos(),
            ),
          ),
        ),
        GoRoute(
          path: Uri.parse(AppRoutes.material()).path,
          builder: (_, _) => const _CadastroDeMaterialFalso(),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> escrever(WidgetTester tester, String chave, String texto) async {
    final campo = find.byKey(ValueKey(chave));
    await tester.ensureVisible(campo);
    await tester.enterText(campo, texto);
    await tester.pumpAndSettle();
  }

  Future<void> escolherMaterial(WidgetTester tester, String nome) async {
    await tocar(tester, find.byKey(const ValueKey('peca-material')));
    await tocar(
      tester,
      find.descendant(of: find.byType(BottomSheet), matching: find.text(nome)),
    );
  }

  Future<void> preencherPeca(WidgetTester tester, _Peca peca) async {
    await escrever(tester, 'peca-descricao', peca.descricao);
    await escolherMaterial(tester, peca.material);
    if (peca.preco case final preco?) {
      await escrever(tester, 'peca-preco', preco);
    }
    await escrever(tester, 'peca-comprimento', peca.comprimento);
    await escrever(tester, 'peca-largura', peca.largura);
    if (peca.espessura case final espessura?) {
      await escrever(tester, 'peca-espessura', espessura);
    }
    await escrever(tester, 'peca-quantidade', peca.quantidade);
  }

  Future<void> preencherProduto(
    WidgetTester tester, {
    required String descricao,
    required String quantidade,
    required String precoBase,
    required List<_Peca> pecas,
  }) async {
    await tocar(
      tester,
      find.textContaining(RegExp('^(Adicionar|Novo) produto')),
    );
    await escrever(tester, 'produto-descricao', descricao);
    await escrever(tester, 'produto-quantidade', quantidade);
    await escrever(tester, 'produto-preco-base', precoBase);
    for (final peca in pecas) {
      await preencherPeca(tester, peca);
      await tocar(tester, find.text('Adicionar peça'));
    }
  }

  /// Valor da [LinhaResumo] de rótulo [rotulo] (a última, se houver mais
  /// de uma).
  String valor(WidgetTester tester, String rotulo) => tester
      .widgetList<LinhaResumo>(find.byType(LinhaResumo))
      .lastWhere((l) => l.rotulo == rotulo)
      .valor;

  Future<void> exemploA(WidgetTester tester) => preencherProduto(
    tester,
    descricao: 'Mesa de jantar sob medida',
    quantidade: '2',
    precoBase: '800,00',
    pecas: [
      _peca('Tampo', _granito, '180', '90'),
      _peca('Perna', _madeira, '75', '8', espessura: '8', quantidade: '4'),
    ],
  );

  Future<void> exemploB(WidgetTester tester, {String? preco}) =>
      preencherProduto(
        tester,
        descricao: 'Painel em MDF',
        quantidade: '3',
        precoBase: '150,00',
        pecas: [_peca('Painel', _mdf, '120', '60', preco: preco)],
      );

  testWidgets('exemplos A e B montados pela interface chegam aos totais da '
      'calculadora', (tester) async {
    await abrir(tester);

    await exemploA(tester);
    // Resumo do produto, antes de adicionar.
    expect(valor(tester, 'Materiais por produto'), r'R$ 553,20');
    expect(valor(tester, 'Preço unitário (com o preço base)'), r'R$ 1.353,20');
    expect(valor(tester, 'Total do produto (× 2)'), r'R$ 2.706,40');
    await tocar(tester, find.text('Adicionar produto'));

    await exemploB(tester);
    await tocar(tester, find.text('Adicionar produto'));

    expect(valor(tester, 'Total dos produtos'), r'R$ 3.350,80');
    expect(find.text('Mesa de jantar sob medida'), findsOneWidget);
    expect(find.text('Painel em MDF'), findsOneWidget);
    final resultado = const CalculadoraOrcamento().calcularOrcamento(
      itens: itens(),
    );
    expect(resultado.totalProdutos, Dinheiro.parse('3.350,80'));
    expect(resultado.itens.map((i) => i.totalItem), [
      Dinheiro.parse('2.706,40'),
      Dinheiro.parse('644,40'),
    ]);
    // As peças guardam a cópia do material, com o preço do cadastro.
    final perna = itens().first.pecas.last;
    expect(perna.quantidadePorProduto, 4);
    expect(perna.material.nome, _madeira);
    expect(perna.material.precoAjustado, isFalse);
    expect(perna.espessuraCm, MedidaCm.parse('8'));
  });

  testWidgets('resumo ao vivo da peça vem da calculadora', (tester) async {
    await abrir(tester);
    await tocar(tester, find.text('Adicionar produto'));
    await preencherPeca(
      tester,
      _peca('Perna', _madeira, '75', '8', espessura: '8', quantidade: '4'),
    );

    expect(valor(tester, 'Consumo por peça'), '0,0048 m³');
    expect(valor(tester, 'Custo unitário'), r'R$ 16,80');
    expect(valor(tester, 'Custo da linha (× 4)'), r'R$ 67,20');
  });

  testWidgets('preço ajustado só na peça fica claro e não muda o cadastro', (
    tester,
  ) async {
    await abrir(tester);
    await exemploB(tester, preco: '95,00');

    expect(find.textContaining('(ajustado)'), findsOneWidget);
    expect(valor(tester, 'Preço unitário (com o preço base)'), r'R$ 218,40');
    await tocar(tester, find.text('Adicionar produto'));

    final material = itens().single.pecas.single.material;
    expect(material.precoAplicado, Dinheiro.parse('95,00'));
    expect(material.precoReferenciaCopiado, Dinheiro.parse('90,00'));
    expect(material.precoAjustado, isTrue);
    final cadastro = await container.read(materiaisProvider.future);
    expect(
      cadastro.singleWhere((m) => m.nome == _mdf).precoReferencia,
      Dinheiro.parse('90,00'),
    );
  });

  testWidgets('preço ajustado no resumo da peça, antes de adicionar', (
    tester,
  ) async {
    await abrir(tester);
    await tocar(tester, find.text('Adicionar produto'));
    await preencherPeca(tester, _peca('Painel', _mdf, '120', '60'));
    expect(
      find.text('Preço do cadastro. Pode ajustar só nesta peça.'),
      findsOneWidget,
    );

    await escrever(tester, 'peca-preco', '95,00');

    expect(valor(tester, 'Custo unitário'), r'R$ 68,40');
    expect(valor(tester, 'Preço ajustado'), contains(r'R$ 90,00'));
    expect(find.textContaining('Ajustado nesta peça'), findsOneWidget);
  });

  testWidgets('medidas ficam desabilitadas até escolher o material', (
    tester,
  ) async {
    await abrir(tester);
    await tocar(tester, find.text('Adicionar produto'));

    bool habilitado(String chave) =>
        tester.widget<TextField>(find.byKey(ValueKey(chave))).enabled ?? true;
    for (final chave in [
      'peca-preco',
      'peca-comprimento',
      'peca-largura',
      'peca-espessura',
    ]) {
      expect(habilitado(chave), isFalse, reason: chave);
    }

    await escolherMaterial(tester, _granito);
    for (final chave in ['peca-preco', 'peca-comprimento', 'peca-largura']) {
      expect(habilitado(chave), isTrue, reason: chave);
    }
    expect(
      find.text('Informativa: não entra no cálculo em m².'),
      findsOneWidget,
    );
  });

  testWidgets('m² → m³ exige revisar as medidas e informar a espessura; '
      'trocar com preço ajustado avisa', (tester) async {
    await abrir(tester);
    await tocar(tester, find.text('Adicionar produto'));
    await preencherPeca(tester, _peca('Tampo', _granito, '120', '60'));
    await escrever(tester, 'peca-preco', '310,00');

    await escolherMaterial(tester, _madeira);
    expect(find.text('Trocar o material?'), findsOneWidget);
    await tocar(tester, _noDialogo('Trocar'));

    // Preço do cadastro do material novo e medidas a revisar.
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('peca-preco')))
          .controller!
          .text,
      '3.500,00',
    );
    expect(find.text('Medidas conferidas'), findsOneWidget);
    OutlinedButton adicionar() => tester.widget<OutlinedButton>(
      find.ancestor(
        of: find.text('Adicionar peça'),
        matching: find.byType(OutlinedButton),
      ),
    );
    expect(adicionar().onPressed, isNull);

    // Editar uma medida conta como revisão.
    await escrever(tester, 'peca-comprimento', '125');
    expect(find.text('Medidas conferidas'), findsNothing);
    await tocar(tester, find.text('Adicionar peça'));
    expect(
      find.text('Informe a espessura: o material é cobrado por m³'),
      findsOneWidget,
    );

    await escrever(tester, 'peca-espessura', '2');
    await tocar(tester, find.text('Adicionar peça'));
    expect(find.text('Nenhuma peça adicionada.'), findsNothing);
    // 1,25 × 0,6 × 0,02 = 0,015 m³ × R$ 3.500,00 = R$ 52,50.
    expect(find.text(r'Custo da linha: R$ 52,50'), findsOneWidget);
  });

  testWidgets('m³ → m² deixa de multiplicar a espessura, que fica '
      'informativa', (tester) async {
    await abrir(tester);
    await tocar(tester, find.text('Adicionar produto'));
    await preencherPeca(
      tester,
      _peca('Perna', _madeira, '75', '8', espessura: '8'),
    );

    await escolherMaterial(tester, _mdf);
    await tocar(tester, find.text('Medidas conferidas'));

    expect(find.text('Espessura (cm), opcional'), findsOneWidget);
    // 0,75 × 0,08 = 0,06 m² × R$ 90,00 = R$ 5,40.
    expect(valor(tester, 'Consumo por peça'), '0,06 m²');
    expect(valor(tester, 'Custo unitário'), r'R$ 5,40');
    await tocar(tester, find.text('Adicionar peça'));
    expect(find.text('75 × 8 × 8 cm'), findsOneWidget);
  });

  testWidgets('peça incompleta ou com quantidade zero não entra', (
    tester,
  ) async {
    await abrir(tester);
    await tocar(tester, find.text('Adicionar produto'));

    await tocar(tester, find.text('Adicionar peça'));
    expect(find.text('Escolha o material'), findsOneWidget);

    await preencherPeca(
      tester,
      _peca('Painel', _mdf, '120', '60', quantidade: '0'),
    );
    await tocar(tester, find.text('Adicionar peça'));
    expect(
      find.text('A quantidade por produto deve ser pelo menos 1'),
      findsOneWidget,
    );
    expect(find.text('Nenhuma peça adicionada.'), findsOneWidget);

    // Produto sem peça e com quantidade zero também não entra.
    await escrever(tester, 'produto-descricao', 'Painel');
    await escrever(tester, 'produto-quantidade', '0');
    await escrever(tester, 'peca-quantidade', '1');
    await tocar(tester, find.text('Adicionar peça'));
    await tocar(tester, find.text('Adicionar produto'));
    expect(
      find.text('A quantidade de produtos deve ser pelo menos 1'),
      findsOneWidget,
    );
    expect(itens(), isEmpty);
  });

  testWidgets('produto sem peça não entra', (tester) async {
    await abrir(tester);
    await tocar(tester, find.text('Adicionar produto'));
    await escrever(tester, 'produto-descricao', 'Painel');

    await tocar(tester, find.text('Adicionar produto'));

    expect(
      find.text('Adicione pelo menos uma peça ao produto'),
      findsOneWidget,
    );
    expect(itens(), isEmpty);
  });

  testWidgets('limpa o formulário da peça ao adicionar e o do produto ao '
      'adicionar o produto', (tester) async {
    await abrir(tester);
    await tocar(tester, find.text('Adicionar produto'));
    await preencherPeca(tester, _peca('Painel', _mdf, '120', '60'));

    await tocar(tester, find.text('Adicionar peça'));

    String texto(String chave) =>
        tester.widget<TextField>(find.byKey(ValueKey(chave))).controller!.text;
    expect(texto('peca-descricao'), isEmpty);
    expect(texto('peca-comprimento'), isEmpty);
    expect(find.text('Escolher material'), findsOneWidget);

    await escrever(tester, 'produto-descricao', 'Painel em MDF');
    await tocar(tester, find.text('Adicionar produto'));
    expect(find.byKey(const ValueKey('produto-descricao')), findsNothing);
    expect(find.text('Novo produto'), findsOneWidget);
  });

  testWidgets('peça em preenchimento avisa antes de adicionar o produto', (
    tester,
  ) async {
    await abrir(tester);
    await exemploB(tester);
    await escrever(tester, 'peca-descricao', 'Reforço');

    await tocar(tester, find.text('Adicionar produto'));
    expect(find.text('Peça não adicionada'), findsOneWidget);
    await tocar(tester, _noDialogo('Cancelar'));
    expect(itens(), isEmpty);

    await tocar(tester, find.text('Adicionar produto'));
    await tocar(tester, _noDialogo('Continuar sem ela'));
    expect(itens().single.pecas, hasLength(1));
  });

  testWidgets('duplicar e editar o produto não muda o original', (
    tester,
  ) async {
    await abrir(tester);
    await exemploB(tester);
    await tocar(tester, find.text('Adicionar produto'));

    await tocar(tester, find.byTooltip('Ações do produto Painel em MDF'));
    await tocar(tester, find.text('Duplicar'));
    expect(itens(), hasLength(2));

    await tocar(tester, find.byTooltip('Ações do produto Painel em MDF').last);
    await tocar(tester, find.text('Editar'));
    await escrever(tester, 'produto-quantidade', '5');
    await tocar(tester, find.text('Salvar produto'));

    final [original, copia] = itens();
    expect(original.quantidadeProdutos, 3);
    expect(copia.quantidadeProdutos, 5);
    expect(copia.id, isNot(original.id));
    expect(copia.pecas.single.id, isNot(original.pecas.single.id));
    expect(valor(tester, 'Total dos produtos'), r'R$ 1.718,40');
  });

  testWidgets('cancelar a edição pede confirmação e não muda o produto', (
    tester,
  ) async {
    await abrir(tester);
    await exemploB(tester);
    await tocar(tester, find.text('Adicionar produto'));

    await tocar(tester, find.byTooltip('Ações do produto Painel em MDF'));
    await tocar(tester, find.text('Editar'));
    await escrever(tester, 'produto-descricao', 'Outro nome');
    await tocar(tester, find.text('Cancelar'));
    expect(find.text('Descartar as alterações do produto?'), findsOneWidget);
    await tocar(tester, _noDialogo('Descartar'));

    expect(itens().single.descricao, 'Painel em MDF');
    expect(container.read(rascunhoProdutoProvider), isNull);
  });

  testWidgets('remover o produto pede confirmação', (tester) async {
    await abrir(tester);
    await exemploB(tester);
    await tocar(tester, find.text('Adicionar produto'));

    await tocar(tester, find.byTooltip('Ações do produto Painel em MDF'));
    await tocar(tester, find.text('Remover'));
    expect(find.text('Remover o produto?'), findsOneWidget);
    await tocar(tester, _noDialogo('Remover'));

    expect(itens(), isEmpty);
  });

  testWidgets('duplicar e editar uma peça não muda a original', (tester) async {
    await abrir(tester);
    await exemploB(tester);

    await tocar(tester, find.byTooltip('Ações da peça Painel'));
    await tocar(tester, find.text('Duplicar'));
    await tocar(tester, find.byTooltip('Ações da peça Painel').last);
    await tocar(tester, find.text('Editar'));
    expect(find.text('Editar peça'), findsOneWidget);
    await escrever(tester, 'peca-comprimento', '100');
    await tocar(tester, find.text('Salvar peça'));
    await tocar(tester, find.text('Adicionar produto'));

    final [original, copia] = itens().single.pecas;
    expect(original.comprimentoCm, MedidaCm.parse('120'));
    expect(copia.comprimentoCm, MedidaCm.parse('100'));
    expect(copia.id, isNot(original.id));
  });

  testWidgets('"Cadastrar material" seleciona o material salvo', (
    tester,
  ) async {
    await abrir(tester);
    await tocar(tester, find.text('Adicionar produto'));

    await tocar(tester, find.byKey(const ValueKey('peca-material')));
    await tocar(tester, find.text('Cadastrar material'));
    await tocar(tester, find.text('Salvar material de teste'));

    expect(find.text('Aço inox'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('peca-preco')))
          .controller!
          .text,
      '120,00',
    );
  });

  group('aviso de produto não adicionado', () {
    Future<bool> sair(WidgetTester tester, {String? resposta}) async {
      final element = tester.element(find.byType(EtapaProdutos));
      final saida = podeSairDaEtapaProdutos(element, element as WidgetRef);
      await tester.pumpAndSettle();
      if (resposta != null) await tocar(tester, _noDialogo(resposta));
      return await saida;
    }

    testWidgets('sem produto em montagem, pode sair', (tester) async {
      await abrir(tester);

      expect(await sair(tester), isTrue);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('formulário intocado fecha sem perguntar', (tester) async {
      await abrir(tester);
      await tocar(tester, find.text('Adicionar produto'));

      expect(await sair(tester), isTrue);
      expect(container.read(rascunhoProdutoProvider), isNull);
    });

    testWidgets('com dados, avisa na etapa e só descarta com confirmação', (
      tester,
    ) async {
      await abrir(tester);
      await tocar(tester, find.text('Adicionar produto'));
      await escrever(tester, 'produto-descricao', 'Painel');

      expect(find.byType(AvisoInline), findsOneWidget);
      expect(await sair(tester, resposta: 'Cancelar'), isFalse);
      expect(container.read(rascunhoProdutoProvider), isNotNull);

      expect(await sair(tester, resposta: 'Descartar'), isTrue);
      expect(container.read(rascunhoProdutoProvider), isNull);
      expect(find.byType(AvisoInline), findsNothing);
    });
  });
}

/// Fica no lugar do formulário de material (V2-C): salva [_inox] e volta
/// com o id, como no contrato de `AppRoutes.material()`.
class _CadastroDeMaterialFalso extends ConsumerWidget {
  const _CadastroDeMaterialFalso();

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    body: Center(
      child: TextButton(
        onPressed: () async {
          await ref.read(materiaisProvider.notifier).salvar(_inox);
          if (context.mounted) context.pop(_inox.id);
        },
        child: const Text('Salvar material de teste'),
      ),
    ),
  );
}
