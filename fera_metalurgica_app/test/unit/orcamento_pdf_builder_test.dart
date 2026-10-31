import 'dart:async';
import 'dart:convert';

import 'package:fera_metalurgica_app/core/domain/dinheiro.dart';
import 'package:fera_metalurgica_app/features/orcamentos/data/pdf/orcamento_pdf_builder.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';

import '../mocks/dados_exemplo.dart';

void main() {
  // O logo vem do bundle de assets.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('fonte do PDF (Inter)', () {
    // "•" (D-01), aspas curvas, travessões, reticências e "Nº".
    const especiais = '• ‘ ’ “ ” – — … Nº ç ã';

    for (final asset in [fontePdfRegular, fontePdfNegrito]) {
      test('$asset desenha "•", aspas curvas e travessão', () async {
        final fonte = TtfParser(await rootBundle.load(asset));

        for (final rune in especiais.runes.where((r) => r != 0x20)) {
          expect(
            fonte.charToGlyphIndexMap[rune],
            isNotNull,
            reason: String.fromCharCode(rune),
          );
        }
      });
    }
  });

  group('gerarOrcamentoPdf', () {
    test('gera um PDF não vazio para cada orçamento de exemplo', () async {
      for (final orcamento in [orcamentoExemploC, orcamentoExemploB]) {
        final bytes = await gerarOrcamentoPdf(orcamento);

        expect(bytes, isNotEmpty, reason: orcamento.id);
        expect(latin1.decode(bytes.sublist(0, 5)), '%PDF-');
      }
    });

    test('desenha "•", aspas curvas e travessão sem trocar nada', () async {
      // O `pdf` avisa por `print` cada caractere que nenhuma fonte desenha.
      final semFonte = <String>[];
      final orcamento = orcamentoExemploC;
      final bytes = await runZoned(
        () => gerarOrcamentoPdf(
          orcamento.copyWith(
            cliente: orcamento.cliente.copyWith(nome: 'José “Zé” – Obras'),
            itens: [
              orcamento.itens.first.copyWith(
                descricao: 'Grade • proteção',
                observacoes: 'Pintura… ‘epóxi’ — 2 demãos',
                quantidadeProdutos: 12,
              ),
              orcamento.itens.last,
            ],
          ),
        ),
        zoneSpecification: ZoneSpecification(
          print: (_, _, _, linha) => semFonte.add(linha),
        ),
      );

      expect(bytes, isNotEmpty);
      expect(semFonte, isEmpty);
    });

    test('não falha com emoji, que a Inter não desenha', () async {
      final semFonte = <String>[];
      final orcamento = orcamentoExemploC;
      final bytes = await runZoned(
        () => gerarOrcamentoPdf(
          orcamento.copyWith(
            cliente: orcamento.cliente.copyWith(nome: 'Obras 🚧'),
          ),
        ),
        zoneSpecification: ZoneSpecification(
          print: (_, _, _, linha) => semFonte.add(linha),
        ),
      );

      expect(bytes, isNotEmpty);
      expect(semFonte, isNotEmpty);
    });

    test('gera mesmo sem itens', () async {
      final bytes = await gerarOrcamentoPdf(
        orcamentoExemploB.copyWith(itens: []),
      );

      expect(bytes, isNotEmpty);
    });
  });

  group('conteúdo do PDF (D-39)', () {
    test('produtos do exemplo C com quantidade, unitário e total', () {
      expect(
        [
          for (final l in linhasProdutosPdf(orcamentoExemploC))
            (l.descricao, l.quantidade, l.precoUnitario, l.total),
        ],
        [
          ('Mesa de jantar sob medida', '2', r'R$ 1.353,20', r'R$ 2.706,40'),
          ('Painel em MDF', '3', r'R$ 214,80', r'R$ 644,40'),
        ],
      );
    });

    test('totais do exemplo C na ordem da D-39', () {
      expect(
        [
          for (final l in linhasTotaisPdf(orcamentoExemploC))
            (l.rotulo, l.valor, l.destaque),
        ],
        [
          ('Total dos produtos', r'R$ 3.350,80', false),
          ('Insumos', r'R$ 100,00', false),
          ('Impostos', r'R$ 200,00', false),
          ('Combustível', r'R$ 50,00', false),
          ('Outros: Frete', r'R$ 30,00', false),
          ('Subtotal', r'R$ 3.730,80', false),
          ('Desconto', r'− R$ 100,00', false),
          ('Total geral', r'R$ 3.630,80', true),
        ],
      );
    });

    test('sem adicionais nem desconto, só as linhas fixas', () {
      expect(
        [for (final l in linhasTotaisPdf(orcamentoExemploB)) l.rotulo],
        ['Total dos produtos', 'Subtotal', 'Total geral'],
      );
    });

    test('usa os totais gravados, sem recalcular', () {
      final gravado = orcamentoExemploC.copyWith(
        totais: orcamentoExemploC.totais.copyWith(
          totalGeral: Dinheiro.parse('1,23'),
        ),
      );

      expect(linhasTotaisPdf(gravado).last.valor, r'R$ 1,23');
    });

    test('não leva o custo das peças nem dos materiais', () {
      // Tampo: R$ 486,00; pernas: R$ 67,20; materiais da mesa: R$ 553,20.
      final textos = [
        for (final l in linhasProdutosPdf(orcamentoExemploC)) ...[
          l.descricao,
          ?l.observacoes,
          l.precoUnitario,
          l.total,
        ],
        for (final l in linhasTotaisPdf(orcamentoExemploC)) l.valor,
      ].join(' ');
      for (final custo in ['486,00', '67,20', '553,20']) {
        expect(textos, isNot(contains(custo)));
      }
    });
  });
}
