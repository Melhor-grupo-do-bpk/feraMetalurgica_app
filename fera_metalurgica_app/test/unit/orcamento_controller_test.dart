import 'package:fera_metalurgica_app/core/di/banco_de_dados.dart';
import 'package:fera_metalurgica_app/core/di/relogio_provider.dart';
import 'package:fera_metalurgica_app/core/domain/dinheiro.dart';
import 'package:fera_metalurgica_app/core/domain/erro_validacao.dart';
import 'package:fera_metalurgica_app/features/empresa/empresa.dart';
import 'package:fera_metalurgica_app/features/orcamentos/data/sqlite_unidade_de_trabalho.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/v2/empresa_snapshot.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/v2/unidade_de_trabalho.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/orcamento_controller.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/wizard/orcamento_controller_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../mocks/banco_de_teste.dart';
import 'v2/dados_v2.dart';

/// Unidade de trabalho que sempre falha, para simular erro de gravação.
class _UnidadeQueFalha implements UnidadeDeTrabalho {
  @override
  Future<T> executarEmTransacao<T>(
    Future<T> Function(RepositoriosTransacao repos) operacao,
  ) async => throw StateError('disco cheio');
}

void main() {
  final agora = DateTime(2026, 10, 28, 10);
  late Database banco;

  Future<ProviderContainer> criar({
    bool comEmpresa = true,
    bool gravacaoFalha = false,
  }) async {
    banco = await bancoDeTeste();
    addTearDown(banco.close);
    if (comEmpresa) await SqliteEmpresaRepository(banco).salvar(empresaTeste);
    final container = ProviderContainer(
      overrides: [
        bancoDeDadosProvider.overrideWithValue(banco),
        agoraProvider.overrideWithValue(agora),
        if (gravacaoFalha)
          unidadeDeTrabalhoProvider.overrideWithValue(_UnidadeQueFalha()),
      ],
    );
    addTearDown(container.dispose);
    // O controller é autoDispose: a tela o mantém vivo; aqui, o listen.
    container.listen(orcamentoControllerProvider, (_, _) {});
    return container;
  }

  late ProviderContainer container;
  OrcamentoController controller() =>
      container.read(orcamentoControllerProvider.notifier);
  EstadoEdicaoOrcamento estado() => container.read(orcamentoControllerProvider);

  /// Preenche a sessão com o exemplo C até a etapa 4.
  void preencherC() {
    controller().selecionarCliente(clienteTeste);
    expect(controller().avancar(), isTrue);
    expect(controller().adicionarItem(itemA), isEmpty);
    expect(controller().adicionarItem(itemB), isEmpty);
    expect(controller().avancar(), isTrue);
    controller().atualizarValores(
      insumos: edicaoC.insumos,
      impostos: edicaoC.impostos,
      combustivel: edicaoC.combustivel,
      outros: edicaoC.outros,
      outrosDescricao: edicaoC.outrosDescricao,
      desconto: edicaoC.desconto,
      validadeDias: 15,
    );
    expect(controller().avancar(), isTrue);
  }

  group('iniciar', () {
    test('sem empresa completa, não começa', () async {
      container = await criar(comEmpresa: false);
      await expectLater(controller().iniciar(), throwsA(isA<StateError>()));
      expect(estado().edicao, isNull);
    });

    test('começa na etapa 1 com a cópia da empresa e uma chave nova', () async {
      container = await criar();
      await controller().iniciar();

      final edicao = estado().edicao!;
      expect(estado().etapaAtual, 1);
      expect(edicao.emitente, empresaTeste.gerarSnapshot());
      expect(edicao.chaveFinalizacao, isNotEmpty);
      expect(edicao.cliente, isNull);
      expect(estado().ehEdicao, isFalse);
    });
  });

  group('etapas', () {
    setUp(() async {
      container = await criar();
      await controller().iniciar();
    });

    test(r'o exemplo C chega a R$ 3.630,80 e é gravado como -01', () async {
      preencherC();
      expect(estado().etapaAtual, 4);
      expect(estado().resumo!.totalGeral, Dinheiro.parse('3.630,80'));
      expect(controller().avancar(), isFalse);

      final salvo = await controller().finalizar();

      expect(salvo!.codigo, '281026-01');
      expect(salvo.totalGeral, Dinheiro.parse('3.630,80'));
      expect(estado(), const EstadoEdicaoOrcamento());
    });

    test('etapa 1 sem cliente não avança e aponta o erro', () {
      expect(controller().avancar(), isFalse);
      expect(estado().etapaAtual, 1);
      expect(estado().erros.single.caminhoCampo, 'cliente');
    });

    test('etapa 2 sem produto não avança', () {
      controller().selecionarCliente(clienteTeste);
      controller().avancar();
      expect(controller().avancar(), isFalse);
      expect(estado().erros.single.codigo, CodigoErroValidacao.vazio);
    });

    test('voltar não perde dados', () {
      preencherC();
      controller()
        ..voltar()
        ..voltar()
        ..voltar();
      expect(estado().etapaAtual, 1);
      controller().voltar();
      expect(estado().etapaAtual, 1);
      expect(estado().edicao!.itens, [itemA, itemB]);
      expect(estado().edicao!.desconto, edicaoC.desconto);
    });

    test('desconto maior que o subtotal: sem resumo e não avança', () {
      controller().selecionarCliente(clienteTeste);
      controller().avancar();
      controller().adicionarItem(itemB);
      controller().avancar();
      expect(estado().resumo!.totalGeral, Dinheiro.parse('644,40'));

      controller().atualizarValores(
        insumos: Dinheiro.zero,
        impostos: Dinheiro.zero,
        combustivel: Dinheiro.zero,
        outros: Dinheiro.zero,
        desconto: Dinheiro.parse('700'),
      );

      expect(estado().resumo, isNull);
      expect(controller().avancar(), isFalse);
      expect(estado().erros.single.codigo, CodigoErroValidacao.excedeSubtotal);
    });

    test('"outros" sem descrição não avança', () {
      controller().selecionarCliente(clienteTeste);
      controller().avancar();
      controller().adicionarItem(itemB);
      controller().avancar();
      controller().atualizarValores(
        insumos: Dinheiro.zero,
        impostos: Dinheiro.zero,
        combustivel: Dinheiro.zero,
        outros: Dinheiro.parse('10'),
        desconto: Dinheiro.zero,
      );
      expect(controller().avancar(), isFalse);
      expect(estado().erros.single.caminhoCampo, 'outrosDescricao');
    });

    test('descartar limpa a sessão', () {
      preencherC();
      controller().descartar();
      expect(estado(), const EstadoEdicaoOrcamento());
    });
  });

  group('produtos e peças', () {
    setUp(() async {
      container = await criar();
      await controller().iniciar();
    });

    List<String> idsItens() => [
      for (final item in estado().edicao!.itens) item.id,
    ];

    test('produto inválido não entra e devolve os erros', () {
      final erros = controller().adicionarItem(
        itemB.copyWith(quantidadeProdutos: 0),
      );
      expect(erros.single.caminhoCampo, 'itens[0].quantidadeProdutos');
      expect(estado().erros, erros);
      expect(estado().edicao!.itens, isEmpty);
    });

    test('editar e remover produto', () {
      controller()
        ..adicionarItem(itemA)
        ..adicionarItem(itemB);
      expect(
        controller().editarItem(itemB.copyWith(quantidadeProdutos: 1)),
        isEmpty,
      );
      expect(estado().edicao!.itens.last.quantidadeProdutos, 1);

      controller().removerItem(itemA.id);
      expect(idsItens(), [itemB.id]);
    });

    test('duplicar é cópia profunda: editar a cópia não muda o original', () {
      controller()
        ..adicionarItem(itemA)
        ..duplicarItem(itemA.id);

      final [original, copia] = estado().edicao!.itens;
      expect(copia.id, isNot(original.id));
      expect(copia.pecas.map((p) => p.id), isNot(contains('tampo')));
      expect(copia.copyWith(id: original.id, pecas: original.pecas), original);

      controller().editarItem(copia.copyWith(descricao: 'Cópia'));
      expect(estado().edicao!.itens.first, itemA);
    });

    test('adicionar, editar, duplicar e remover peça', () {
      controller().adicionarItem(itemB);
      final painel = itemB.pecas.single;

      expect(
        controller().adicionarPeca(itemB.id, painel.copyWith(id: 'p2')),
        isEmpty,
      );
      expect(
        controller().editarPeca(
          itemB.id,
          painel.copyWith(quantidadePorProduto: 2),
        ),
        isEmpty,
      );
      controller().duplicarPeca(itemB.id, 'p2');

      final pecas = estado().edicao!.itens.single.pecas;
      expect(pecas, hasLength(3));
      expect(pecas.first.quantidadePorProduto, 2);
      expect(pecas[2].id, isNot('p2'));

      controller()
        ..removerPeca(itemB.id, 'p2')
        ..removerPeca(itemB.id, pecas[2].id);
      expect(estado().edicao!.itens.single.pecas.map((p) => p.id), [painel.id]);
    });

    test('peça inválida não entra', () {
      controller().adicionarItem(itemA);
      final perna = itemA.pecas.last;
      final erros = controller().adicionarPeca(
        itemA.id,
        perna.copyWith(id: 'perna-2', espessuraCm: null),
      );
      expect(erros.single.caminhoCampo, 'itens[0].pecas[2].espessuraCm');
      expect(estado().edicao!.itens.single.pecas, hasLength(2));
    });

    test('a última peça não sai', () {
      controller().adicionarItem(itemB);
      final erros = controller().removerPeca(itemB.id, itemB.pecas.single.id);
      expect(erros.single.codigo, CodigoErroValidacao.vazio);
      expect(estado().edicao!.itens.single.pecas, hasLength(1));
    });
  });

  group('finalizar', () {
    test(
      'sessão inválida devolve null com os erros e mantém a sessão',
      () async {
        container = await criar();
        await controller().iniciar();
        controller().adicionarItem(itemB);

        expect(await controller().finalizar(), isNull);
        expect(estado().erros.map((e) => e.caminhoCampo), contains('cliente'));
        expect(estado().edicao!.itens, hasLength(1));
        expect(estado().finalizando, isFalse);
      },
    );

    test('clique duplo grava um orçamento só', () async {
      container = await criar();
      await controller().iniciar();
      preencherC();

      final primeiro = controller().finalizar();
      expect(estado().finalizando, isTrue);
      final segundo = controller().finalizar();

      expect(await segundo, isNull);
      expect(await primeiro, isNotNull);
      expect(await banco.query('orcamentos'), hasLength(1));
    });

    test('falha de gravação mantém a sessão e relança o erro', () async {
      container = await criar(gravacaoFalha: true);
      await controller().iniciar();
      preencherC();
      final antes = estado().edicao;

      await expectLater(controller().finalizar(), throwsA(isA<StateError>()));

      expect(estado().edicao, antes);
      expect(estado().finalizando, isFalse);
      expect(estado().etapaAtual, 4);
    });
  });

  group('edição (D-30)', () {
    test('abre a cópia do orçamento salvo e grava a rev. 2', () async {
      container = await criar();
      await controller().iniciar();
      preencherC();
      final salvo = (await controller().finalizar())!;

      await controller().iniciarEdicao(salvo.id);
      final edicao = estado().edicao!;
      expect(estado().ehEdicao, isTrue);
      expect(estado().etapaAtual, 1);
      expect(edicao.codigo, salvo.codigo);
      expect(edicao.revisao, 1);
      expect(edicao.itens, salvo.itens);
      expect(edicao.chaveFinalizacao, isNot(salvo.chaveFinalizacao));
      expect(estado().resumo, salvo.totais);

      controller().removerItem(itemA.id);
      final revisado = await controller().finalizar();

      expect(revisado!.id, salvo.id);
      expect(revisado.codigoExibicao, '281026-01 rev. 2');
      expect(revisado.itens, [itemB]);
    });

    test('orçamento inexistente não abre', () async {
      container = await criar();
      await expectLater(
        controller().iniciarEdicao('nao-existe'),
        throwsA(isA<StateError>()),
      );
    });
  });
}
