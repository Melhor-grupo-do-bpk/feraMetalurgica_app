import 'dart:convert';

import 'package:fera_metalurgica_app/features/orcamentos/data/pdf/orcamento_pdf_builder.dart';
import 'package:fera_metalurgica_app/features/orcamentos/orcamentos.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // O logo vem do bundle de assets.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('textoParaPdf', () {
    test('mantém Latin-1 (acentos, Nº, ×, ·)', () {
      const texto = 'Orçamento Nº 00482: São Paulo, 50×50mm · ÀÉÎÕÜ ñ';
      expect(textoParaPdf(texto), texto);
    });

    test('troca aspas curvas por retas', () {
      expect(textoParaPdf('‘a’ “b” „c‟'), '\'a\' "b" "c"');
    });

    test('troca travessões por hífen', () {
      expect(textoParaPdf('a – b — c − d'), 'a - b - c - d');
    });

    test('troca "•" por "·" e "…" por "..."', () {
      expect(textoParaPdf('2.50m • Aço…'), '2.50m · Aço...');
    });

    test('troca espaços especiais por espaço comum', () {
      // U+2009 (espaço fino) e U+202F (espaço fino inseparável).
      final texto = String.fromCharCodes([0x31, 0x2009, 0x6D, 0x202F, 0x75]);
      expect(textoParaPdf(texto), '1 m u');
    });

    test('troca o resto por "?" (um por caractere, emoji inclusive)', () {
      expect(textoParaPdf('Obra 👍 中'), 'Obra ? ?');
    });

    test('não deixa nada acima de U+00FF', () {
      final saida = textoParaPdf('João “Zé” – 🚧 Ω ✓ • …');
      expect(saida.runes.every((r) => r <= 0xFF), isTrue);
    });
  });

  group('gerarOrcamentoPdf', () {
    test('gera um PDF não vazio para cada orçamento do seed', () async {
      for (final orcamento in orcamentosSeed) {
        final bytes = await gerarOrcamentoPdf(orcamento);

        expect(bytes, isNotEmpty, reason: orcamento.id);
        expect(latin1.decode(bytes.sublist(0, 5)), '%PDF-');
      }
    });

    test('não falha com caracteres fora do Latin-1 digitados', () async {
      final orcamento = orcamentosSeed.first;
      final bytes = await gerarOrcamentoPdf(
        orcamento.copyWith(
          cliente: orcamento.cliente.copyWith(
            nome: 'José “Zé” – Obras 🚧',
            email: 'ze@obras.com',
          ),
          itens: [
            orcamento.itens.first.copyWith(
              tipoServico: 'Grade • proteção',
              especificacoes: 'Pintura… “epóxi” ✓',
              quantidade: 12,
            ),
            const ItemOrcamento(id: 'sem-detalhes', tipoServico: 'Visita'),
          ],
        ),
      );

      expect(bytes, isNotEmpty);
    });

    test('gera mesmo sem itens', () async {
      final bytes = await gerarOrcamentoPdf(
        orcamentosSeed.first.copyWith(itens: []),
      );

      expect(bytes, isNotEmpty);
    });
  });
}
