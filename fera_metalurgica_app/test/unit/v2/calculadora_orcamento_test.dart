import 'package:fera_metalurgica_app/core/domain/consumo.dart';
import 'package:fera_metalurgica_app/core/domain/dinheiro.dart';
import 'package:fera_metalurgica_app/core/domain/erro_validacao.dart';
import 'package:fera_metalurgica_app/core/domain/medida_cm.dart';
import 'package:fera_metalurgica_app/features/materiais/materiais.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/calculadora_orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/item_orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/material_snapshot.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/validacao_orcamento.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dados_v2.dart';

const _calc = CalculadoraOrcamento();

Dinheiro _r(String texto) => Dinheiro.parse(texto);

/// Produto de uma peça só, com base [base] e [quantidade] produtos.
ItemOrcamento _produto({
  required String base,
  required List<({String id, int qtd, String c, String l, String? e})> pecas,
  required MaterialSnapshot material,
  int quantidade = 1,
}) => ItemOrcamento(
  id: 'item',
  descricao: 'Produto',
  quantidadeProdutos: quantidade,
  precoBase: _r(base),
  pecas: [
    for (final p in pecas)
      peca(
        id: p.id,
        material: material,
        comprimento: p.c,
        largura: p.l,
        espessura: p.e,
        quantidade: p.qtd,
      ),
  ],
);

void main() {
  test('versão do cálculo é 1', () {
    expect(CalculadoraOrcamento.versaoCalculo, 1);
  });

  group('Exemplo A: mesa de granito e madeira', () {
    final resultado = _calc.calcularItem(itemA);
    final tampo = resultado.pecas[0];
    final perna = resultado.pecas[1];

    test(r'tampo: 1,62 m² × R$ 300,00 = R$ 486,00', () {
      expect(tampo.consumoUnitario.formatadoComUnidade, '1,62 m²');
      expect(tampo.custoUnitario, _r('486,00'));
      expect(tampo.custoLinha, _r('486,00'));
    });

    test(r'perna: 0,0048 m³ × R$ 3.500,00 = R$ 16,80; quatro = 67,20', () {
      expect(perna.consumoUnitario.formatadoComUnidade, '0,0048 m³');
      expect(perna.custoUnitario, _r('16,80'));
      expect(perna.custoLinha, _r('67,20'));
      expect(perna.consumoLinha.formatado, '0,0192');
    });

    test(r'materiais R$ 553,20, unitário R$ 1.353,20, item R$ 2.706,40', () {
      expect(resultado.custoMateriais, _r('553,20'));
      expect(resultado.precoUnitario, _r('1.353,20'));
      expect(resultado.totalItem, _r('2.706,40'));
      expect(resultado.totalItem.formatado, r'R$ 2.706,40');
    });

    test('consumo total informativo: 3,24 m² e 0,0384 m³, sem misturar', () {
      expect((tampo.consumoLinha * 2).formatadoComUnidade, '3,24 m²');
      expect((perna.consumoLinha * 2).formatadoComUnidade, '0,0384 m³');
      expect(
        () => tampo.consumoLinha + perna.consumoLinha,
        throwsArgumentError,
      );
    });
  });

  test(r'Exemplo B: painel em MDF dá R$ 214,80 por painel e R$ 644,40', () {
    final resultado = _calc.calcularItem(itemB);
    expect(resultado.pecas.single.consumoUnitario.formatado, '0,72');
    expect(resultado.custoMateriais, _r('64,80'));
    expect(resultado.precoUnitario, _r('214,80'));
    expect(resultado.totalItem, _r('644,40'));
  });

  test(r'Exemplo C: fechamento dá total geral de R$ 3.630,80', () {
    final totais = _calc.calcularOrcamento(
      itens: edicaoC.itens,
      insumos: edicaoC.insumos,
      impostos: edicaoC.impostos,
      combustivel: edicaoC.combustivel,
      outros: edicaoC.outros,
      desconto: edicaoC.desconto,
    );
    expect(totais.totalProdutos, _r('3.350,80'));
    expect(totais.totalAdicionais, _r('380,00'));
    expect(totais.subtotal, _r('3.730,80'));
    expect(totais.desconto, _r('100,00'));
    expect(totais.totalGeral, _r('3.630,80'));
    expect(totais.totalGeral.formatado, r'R$ 3.630,80');
    expect(totais.itens.map((i) => i.itemId), ['item-a', 'item-b']);
  });

  test(r'modelo antigo em m³: 200 × 90 × 8 dá R$ 504,00 e R$ 1.304,00', () {
    final resultado = _calc.calcularItem(
      _produto(
        base: '800,00',
        material: madeira.gerarSnapshot(),
        pecas: [(id: 'p', qtd: 1, c: '200', l: '90', e: '8')],
      ),
    );
    expect(resultado.custoMateriais, _r('504,00'));
    expect(resultado.precoUnitario, _r('1.304,00'));
  });

  test(r'medidas diferentes em linhas separadas: pernas somam R$ 64,96', () {
    final resultado = _calc.calcularItem(
      _produto(
        base: '0',
        material: madeira.gerarSnapshot(),
        pecas: [
          (id: 'longas', qtd: 2, c: '75', l: '8', e: '8'),
          (id: 'curtas', qtd: 2, c: '70', l: '8', e: '8'),
        ],
      ),
    );
    expect(resultado.pecas[0].custoLinha, _r('33,60'));
    expect(resultado.pecas[1].custoLinha, _r('31,36'));
    expect(resultado.custoMateriais, _r('64,96'));
  });

  group('precisão', () {
    final material = mdf.gerarSnapshot().copyWith(
      precoAplicado: _r('1,00'),
      precoReferenciaCopiado: _r('1,00'),
    );

    test(r'0,005 m² × R$ 1,00 = R$ 0,01 por peça; três peças = R$ 0,03', () {
      final resultado = _calc.calcularItem(
        _produto(
          base: '0',
          material: material,
          pecas: [(id: 'p', qtd: 3, c: '10', l: '5', e: null)],
        ),
      );
      final linha = resultado.pecas.single;
      expect(linha.consumoUnitario.formatado, '0,005');
      expect(linha.custoUnitario, _r('0,01'));
      expect(linha.custoLinha, _r('0,03'));
      // Arredondar só a soma (0,015 → 0,02) daria outro resultado.
      expect(linha.custoLinha, isNot(_r('0,02')));
    });

    test(r'half-up exato onde double erraria (1,005 m² × R$ 1,00)', () {
      // Em double, 1.005 * 100 = 100.49999999999999 e arredondaria para
      // R$ 1,00. Com inteiros, 100,5 centavos sobem para R$ 1,01.
      final linha = _calc
          .calcularItem(
            _produto(
              base: '0',
              material: material,
              pecas: [(id: 'p', qtd: 1, c: '100,5', l: '100', e: null)],
            ),
          )
          .pecas
          .single;
      expect(linha.consumoUnitario.formatado, '1,005');
      expect(linha.custoUnitario, _r('1,01'));
    });

    test('consumo intermediário não é arredondado (12 casas)', () {
      // 0,01 × 0,01 × 0,01 m = 0,000001 m³: menor que um centavo de
      // consumo, mas exato.
      final linha = _calc.calcularPeca(
        peca(
          id: 'p',
          material: madeira.gerarSnapshot(),
          comprimento: '0,01',
          largura: '0,01',
          espessura: '0,01',
        ),
      );
      expect(linha.consumoUnitario.textoCanonico, '0.000000000001');
      expect(linha.custoUnitario, Dinheiro.zero);
    });
  });

  group('mudança de preço', () {
    test(r'cadastro muda depois: a peça salva continua em R$ 90,00/m²', () {
      final salvo = itemB;
      final cadastroNovo = mdf.copyWith(precoReferencia: _r('100,00'));
      expect(cadastroNovo.precoReferencia, _r('100,00'));
      final resultado = _calc.calcularItem(salvo);
      expect(salvo.pecas.single.material.precoAplicado, _r('90,00'));
      expect(resultado.precoUnitario, _r('214,80'));

      final novaSelecao = salvo.copyWith(
        pecas: [
          salvo.pecas.single.copyWith(material: cadastroNovo.gerarSnapshot()),
        ],
      );
      final novo = _calc.calcularItem(novaSelecao);
      expect(novo.custoMateriais, _r('72,00'));
      expect(novo.precoUnitario, _r('222,00'));
    });

    test(r'preço ajustado só na peça: R$ 95,00/m² dá painel R$ 218,40', () {
      final snapshot = mdf.gerarSnapshot();
      expect(snapshot.precoAjustado, isFalse);
      final ajustado = snapshot.copyWith(precoAplicado: _r('95,00'));
      expect(ajustado.precoAjustado, isTrue);
      expect(ajustado.precoReferenciaCopiado, _r('90,00'));
      expect(mdf.precoReferencia, _r('90,00'));

      final item = itemB.copyWith(
        pecas: [itemB.pecas.single.copyWith(material: ajustado)],
      );
      final resultado = _calc.calcularItem(item);
      expect(resultado.custoMateriais, _r('68,40'));
      expect(resultado.precoUnitario, _r('218,40'));
    });

    test('editar ou inativar o material não altera a cópia da peça', () {
      final snapshot = granito.gerarSnapshot();
      final editado = granito.copyWith(
        ativo: false,
        nome: 'Outro',
        precoReferencia: _r('1'),
      );
      expect(editado.id, granito.id);
      expect(snapshot.nome, 'Granito - variedade B - 2 cm');
      expect(snapshot.precoAplicado, _r('300,00'));
      expect(snapshot.materialOrigemId, editado.id);
      expect(
        const CalculadoraOrcamento().calcularItem(itemA).totalItem,
        _r('2.706,40'),
      );
    });
  });

  group('troca de unidade', () {
    final base = peca(
      id: 'p',
      material: mdf.gerarSnapshot(),
      comprimento: '120',
      largura: '60',
      espessura: '1,5',
    );

    test('em m² a espessura é informativa e não multiplica', () {
      final linha = _calc.calcularPeca(base);
      expect(linha.consumoUnitario.formatadoComUnidade, '0,72 m²');
      expect(linha.custoUnitario, _r('64,80'));
    });

    test('m² → m³ exige espessura válida', () {
      final semEspessura = base.copyWith(
        material: madeira.gerarSnapshot(),
        espessuraCm: null,
      );
      expect(
        validarPeca(semEspessura).single,
        isA<ErroValidacao>()
            .having((e) => e.caminhoCampo, 'caminho', 'espessuraCm')
            .having((e) => e.codigo, 'codigo', CodigoErroValidacao.obrigatorio),
      );
      expect(() => _calc.calcularPeca(semEspessura), throwsArgumentError);
      expect(
        validarPeca(semEspessura.copyWith(espessuraCm: const MedidaCm(0))),
        hasLength(1),
      );

      final comEspessura = base.copyWith(material: madeira.gerarSnapshot());
      expect(validarPeca(comEspessura), isEmpty);
      final linha = _calc.calcularPeca(comEspessura);
      expect(linha.unidade, UnidadeCobranca.m3);
      expect(linha.consumoUnitario.formatado, '0,0108');
      expect(linha.custoUnitario, _r('37,80'));
    });

    test('m³ → m² deixa de multiplicar a espessura', () {
      final m3 = base.copyWith(material: madeira.gerarSnapshot());
      final deVolta = m3.copyWith(material: mdf.gerarSnapshot());
      expect(
        _calc.calcularPeca(deVolta).consumoUnitario,
        Consumo(
          unidade: UnidadeCobranca.m2,
          valor: BigInt.parse('720000000000'),
        ),
      );
    });
  });

  test('rejeita total geral negativo', () {
    expect(
      () => _calc.calcularOrcamento(itens: [itemB], desconto: _r('644,41')),
      throwsArgumentError,
    );
    final zerado = _calc.calcularOrcamento(
      itens: [itemB],
      desconto: _r('644,40'),
    );
    expect(zerado.totalGeral, Dinheiro.zero);
    expect(zerado.totalGeralZero, isTrue);
  });

  test('determinística: o mesmo item dá o mesmo resultado', () {
    expect(_calc.calcularItem(itemA), _calc.calcularItem(itemA));
  });
}
