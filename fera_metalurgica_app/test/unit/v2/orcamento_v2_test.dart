import 'dart:convert';

import 'package:fera_metalurgica_app/core/domain/dinheiro.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/v2/calculadora_orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/v2/orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/v2/orcamento_em_edicao.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/v2/status_orcamento.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dados_v2.dart';

Orcamento _orcamentoC({int revisao = 1, int? validadeDias = 15}) {
  final totais = const CalculadoraOrcamento().calcularOrcamento(
    itens: edicaoC.itens,
    insumos: edicaoC.insumos,
    impostos: edicaoC.impostos,
    combustivel: edicaoC.combustivel,
    outros: edicaoC.outros,
    desconto: edicaoC.desconto,
  );
  return Orcamento(
    id: 'orcamento-1',
    codigo: '281026-03',
    revisao: revisao,
    chaveFinalizacao: edicaoC.chaveFinalizacao,
    criadoEm: DateTime(2026, 10, 28, 9, 30),
    atualizadoEm: DateTime(2026, 10, 29, 14),
    status: StatusOrcamento.criado,
    cliente: edicaoC.cliente!,
    emitente: edicaoC.emitente,
    itens: edicaoC.itens,
    insumos: edicaoC.insumos,
    impostos: edicaoC.impostos,
    combustivel: edicaoC.combustivel,
    outros: edicaoC.outros,
    outrosDescricao: edicaoC.outrosDescricao,
    desconto: edicaoC.desconto,
    validadeDias: validadeDias,
    observacoes: edicaoC.observacoes,
    totais: totais,
    versaoCalculo: CalculadoraOrcamento.versaoCalculo,
  );
}

void main() {
  group('Orcamento', () {
    test('código exibido mostra a revisão a partir da 2ª', () {
      expect(_orcamentoC().codigoExibicao, '281026-03');
      expect(_orcamentoC(revisao: 2).codigoExibicao, '281026-03 rev. 2');
    });

    test('total geral vem dos totais gravados', () {
      expect(_orcamentoC().totalGeral, Dinheiro.parse('3.630,80'));
    });

    test('validade conta dias corridos a partir de atualizadoEm', () {
      expect(_orcamentoC().dataValidade, DateTime(2026, 11, 13));
      expect(_orcamentoC(validadeDias: 3).dataValidade, DateTime(2026, 11));
      expect(_orcamentoC(validadeDias: null).dataValidade, isNull);
    });

    test('JSON de ida e volta, com resultados e consumo em texto', () {
      final original = _orcamentoC();
      final json = jsonDecode(jsonEncode(original)) as Map<String, dynamic>;

      expect(json['status'], 'criado');
      expect(json['insumos'], 10000);
      expect(json['cliente'], containsPair('documento', '52998224725'));
      final totais = json['totais'] as Map<String, dynamic>;
      expect(totais['totalGeral'], 363080);
      final item = (totais['itens'] as List<dynamic>).first as Map;
      final perna = (item['pecas'] as List<dynamic>)[1] as Map;
      expect(perna['consumoUnitario'], {
        'unidade': 'm3',
        'valor': '0.004800000000',
      });
      final pecaJson =
          ((json['itens'] as List<dynamic>).first as Map)['pecas'] as List;
      expect((pecaJson[1] as Map)['espessuraCm'], 800);
      expect((pecaJson[0] as Map)['espessuraCm'], isNull);

      expect(Orcamento.fromJson(json), original);
    });
  });

  test('OrcamentoEmEdicao: JSON de ida e volta e padrões', () {
    final json = jsonDecode(jsonEncode(edicaoC)) as Map<String, dynamic>;
    expect(OrcamentoEmEdicao.fromJson(json), edicaoC);

    final nova = OrcamentoEmEdicao(
      chaveFinalizacao: 'k',
      emitente: edicaoC.emitente,
    );
    expect(nova.itens, isEmpty);
    expect(nova.desconto, Dinheiro.zero);
    expect(nova.cliente, isNull);
    expect(nova.ehEdicao, isFalse);
    expect(
      nova.copyWith(orcamentoOrigemId: 'o', codigo: 'c', revisao: 1).ehEdicao,
      isTrue,
    );
  });

  group('duplicação', () {
    test('peça duplicada tem id novo e o resto igual', () {
      final original = itemA.pecas[1];
      final copia = original.duplicar('perna-2');
      expect(copia.id, 'perna-2');
      expect(copia.copyWith(id: original.id), original);
    });

    test('item duplicado é cópia profunda com ids novos', () {
      var n = 0;
      String gerarId() => 'novo-${++n}';
      final copia = itemA.duplicarComNovosIds(gerarId);

      expect(copia.id, 'novo-1');
      expect(copia.pecas.map((p) => p.id), ['novo-2', 'novo-3']);
      expect(copia.descricao, itemA.descricao);

      final editada = copia.copyWith(
        quantidadeProdutos: 5,
        pecas: [copia.pecas[0].copyWith(descricao: 'Tampo novo')],
      );
      expect(editada.pecas, hasLength(1));
      expect(itemA.quantidadeProdutos, 2);
      expect(itemA.pecas, hasLength(2));
      expect(itemA.pecas[0].descricao, 'Tampo');
      expect(itemA.pecas.map((p) => p.id), ['tampo', 'perna']);
    });

    test('quantidade de produtos não altera a quantidade por produto', () {
      final mais = itemA.copyWith(quantidadeProdutos: 10);
      expect(mais.pecas[1].quantidadePorProduto, 4);
    });
  });

  test('snapshots de cliente e empresa guardam a origem', () {
    expect(edicaoC.cliente!.clienteOrigemId, clienteTeste.id);
    expect(edicaoC.cliente!.documento, clienteTeste.documento);
    expect(edicaoC.emitente.empresaOrigemId, empresaTeste.id);
    expect(edicaoC.emitente.email, empresaTeste.email);
  });
}
