import 'dart:async';
import 'dart:convert';

import 'package:fera_metalurgica_app/features/orcamentos/data/pdf/orcamento_pdf_builder.dart';
import 'package:fera_metalurgica_app/features/orcamentos/orcamentos.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';

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
    test('gera um PDF não vazio para cada orçamento do seed', () async {
      for (final orcamento in orcamentosSeed) {
        final bytes = await gerarOrcamentoPdf(orcamento);

        expect(bytes, isNotEmpty, reason: orcamento.id);
        expect(latin1.decode(bytes.sublist(0, 5)), '%PDF-');
      }
    });

    test('desenha "•", aspas curvas e travessão sem trocar nada', () async {
      // O `pdf` avisa por `print` cada caractere que nenhuma fonte desenha.
      final semFonte = <String>[];
      final orcamento = orcamentosSeed.first;
      final bytes = await runZoned(
        () => gerarOrcamentoPdf(
          orcamento.copyWith(
            cliente: orcamento.cliente.copyWith(
              nome: 'José “Zé” – Obras',
              email: 'ze@obras.com',
            ),
            itens: [
              orcamento.itens.first.copyWith(
                tipoServico: 'Grade • proteção',
                especificacoes: 'Pintura… ‘epóxi’ — 2 demãos',
                quantidade: 12,
              ),
              const ItemOrcamento(id: 'sem-detalhes', tipoServico: 'Visita'),
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
      final orcamento = orcamentosSeed.first;
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
        orcamentosSeed.first.copyWith(itens: []),
      );

      expect(bytes, isNotEmpty);
    });
  });
}
