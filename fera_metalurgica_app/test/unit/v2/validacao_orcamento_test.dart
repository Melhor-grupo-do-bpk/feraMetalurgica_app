import 'package:fera_metalurgica_app/core/domain/dinheiro.dart';
import 'package:fera_metalurgica_app/core/domain/documento.dart';
import 'package:fera_metalurgica_app/core/domain/erro_validacao.dart';
import 'package:fera_metalurgica_app/core/domain/medida_cm.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/v2/calculadora_orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/v2/validacao_orcamento.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dados_v2.dart';

List<(String, CodigoErroValidacao)> _resumo(List<ErroValidacao> erros) =>
    erros.map((e) => (e.caminhoCampo, e.codigo)).toList();

void main() {
  test('o exemplo C completo é válido', () {
    expect(validarOrcamento(edicaoC), isEmpty);
  });

  group('peça', () {
    final perna = itemA.pecas[1];

    test('cada regra gera o erro com o caminho certo', () {
      final invalida = perna.copyWith(
        descricao: ' ',
        quantidadePorProduto: 0,
        comprimentoCm: const MedidaCm(0),
        larguraCm: const MedidaCm(-1),
        espessuraCm: null,
        material: perna.material.copyWith(
          nome: '',
          precoAplicado: Dinheiro.zero,
        ),
      );
      expect(_resumo(validarPeca(invalida, caminho: 'itens[0].pecas[1]')), [
        ('itens[0].pecas[1].descricao', CodigoErroValidacao.obrigatorio),
        ('itens[0].pecas[1].material.nome', CodigoErroValidacao.obrigatorio),
        (
          'itens[0].pecas[1].material.precoAplicado',
          CodigoErroValidacao.naoPositivo,
        ),
        (
          'itens[0].pecas[1].quantidadePorProduto',
          CodigoErroValidacao.minimoUm,
        ),
        ('itens[0].pecas[1].comprimentoCm', CodigoErroValidacao.naoPositivo),
        ('itens[0].pecas[1].larguraCm', CodigoErroValidacao.naoPositivo),
        ('itens[0].pecas[1].espessuraCm', CodigoErroValidacao.obrigatorio),
      ]);
    });

    test('em m² a espessura é opcional, mas se informada é positiva', () {
      final tampo = itemA.pecas[0];
      expect(validarPeca(tampo), isEmpty);
      expect(
        _resumo(validarPeca(tampo.copyWith(espessuraCm: const MedidaCm(0)))),
        [('espessuraCm', CodigoErroValidacao.naoPositivo)],
      );
    });
  });

  group('produto', () {
    test('cada regra gera o erro com o caminho certo', () {
      final invalido = itemB.copyWith(
        descricao: '',
        quantidadeProdutos: 0,
        precoBase: const Dinheiro(-1),
        pecas: [],
      );
      expect(_resumo(validarItem(invalido, caminho: 'itens[1]')), [
        ('itens[1].descricao', CodigoErroValidacao.obrigatorio),
        ('itens[1].quantidadeProdutos', CodigoErroValidacao.minimoUm),
        ('itens[1].precoBase', CodigoErroValidacao.negativo),
        ('itens[1].pecas', CodigoErroValidacao.vazio),
      ]);
    });

    test('preço base zero é aceito', () {
      expect(validarItem(itemB.copyWith(precoBase: Dinheiro.zero)), isEmpty);
    });
  });

  group('orçamento', () {
    test('quantidade zero bloqueia, com caminho do item', () {
      final edicao = edicaoC.copyWith(
        itens: [itemA, itemB.copyWith(quantidadeProdutos: 0)],
      );
      expect(_resumo(validarOrcamento(edicao)), [
        ('itens[1].quantidadeProdutos', CodigoErroValidacao.minimoUm),
      ]);
    });

    test('peça incompleta bloqueia: espessura em m³', () {
      final perna = itemA.pecas[1].copyWith(espessuraCm: null);
      final edicao = edicaoC.copyWith(
        itens: [
          itemA.copyWith(pecas: [itemA.pecas[0], perna]),
        ],
      );
      expect(_resumo(validarOrcamento(edicao)), [
        ('itens[0].pecas[1].espessuraCm', CodigoErroValidacao.obrigatorio),
      ]);
    });

    test('sem cliente e sem itens', () {
      final edicao = edicaoC.copyWith(cliente: null, itens: []);
      expect(_resumo(validarOrcamento(edicao)), [
        ('cliente', CodigoErroValidacao.obrigatorio),
        ('itens', CodigoErroValidacao.vazio),
      ]);
    });

    test('cliente e emitente inválidos usam os prefixos', () {
      final edicao = edicaoC.copyWith(
        cliente: edicaoC.cliente!.copyWith(
          documento: const Documento('52998224724'),
        ),
        emitente: edicaoC.emitente.copyWith(telefone: ''),
      );
      expect(_resumo(validarOrcamento(edicao)), [
        ('cliente.documento', CodigoErroValidacao.invalido),
        ('emitente.telefone', CodigoErroValidacao.obrigatorio),
      ]);
    });

    test('adicionais negativos', () {
      final edicao = edicaoC.copyWith(
        insumos: const Dinheiro(-1),
        impostos: const Dinheiro(-1),
        combustivel: const Dinheiro(-1),
        outros: const Dinheiro(-1),
        desconto: const Dinheiro(-1),
      );
      expect(_resumo(validarOrcamento(edicao)), [
        ('insumos', CodigoErroValidacao.negativo),
        ('impostos', CodigoErroValidacao.negativo),
        ('combustivel', CodigoErroValidacao.negativo),
        ('outros', CodigoErroValidacao.negativo),
        ('desconto', CodigoErroValidacao.negativo),
      ]);
    });

    test('"outros" maior que zero exige descrição', () {
      expect(
        _resumo(validarOrcamento(edicaoC.copyWith(outrosDescricao: ' '))),
        [('outrosDescricao', CodigoErroValidacao.obrigatorio)],
      );
      expect(
        validarOrcamento(
          edicaoC.copyWith(outros: Dinheiro.zero, outrosDescricao: null),
        ),
        isEmpty,
      );
    });

    test('validade, se informada, é de pelo menos 1 dia', () {
      expect(_resumo(validarOrcamento(edicaoC.copyWith(validadeDias: 0))), [
        ('validadeDias', CodigoErroValidacao.naoPositivo),
      ]);
      expect(validarOrcamento(edicaoC.copyWith(validadeDias: null)), isEmpty);
    });

    test('desconto maior que o subtotal bloqueia; igual é aceito', () {
      // Subtotal do exemplo C: R$ 3.730,80.
      expect(
        _resumo(
          validarOrcamento(
            edicaoC.copyWith(desconto: Dinheiro.parse('3.730,81')),
          ),
        ),
        [('desconto', CodigoErroValidacao.excedeSubtotal)],
      );
      final zerado = edicaoC.copyWith(desconto: Dinheiro.parse('3.730,80'));
      expect(validarOrcamento(zerado), isEmpty);
    });

    test('total zero não é erro, mas é sinalizado', () {
      final zerado = edicaoC.copyWith(desconto: Dinheiro.parse('3.730,80'));
      final totais = const CalculadoraOrcamento().calcularOrcamento(
        itens: zerado.itens,
        insumos: zerado.insumos,
        impostos: zerado.impostos,
        combustivel: zerado.combustivel,
        outros: zerado.outros,
        desconto: zerado.desconto,
      );
      expect(totais.totalGeralZero, isTrue);
      expect(validarOrcamento(zerado), isEmpty);
    });

    test('não altera os dados validados', () {
      final antes = edicaoC.copyWith(validadeDias: 0);
      validarOrcamento(antes);
      expect(antes.validadeDias, 0);
    });
  });
}
