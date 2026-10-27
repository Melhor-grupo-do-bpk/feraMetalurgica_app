import 'package:fera_metalurgica_app/core/utils/currency_format.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/mensagem_whatsapp.dart';
import 'package:fera_metalurgica_app/features/orcamentos/orcamentos.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final orcamento = orcamentosSeed.firstWhere((o) => o.id == '00482');

  test('monta o resumo do #00482 (D-15)', () {
    expect(
      montarMensagemWhatsApp(orcamento),
      'Olá, João da Silva! Segue o resumo do orçamento Nº 00482 da '
      'Fera Metalurgica LTDA.\n'
      '\n'
      'Projeto: Portão metálico\n'
      r'Valor total: R$ 8.450,00'
      '\n'
      'Prazo: 15 dias úteis após aprovação e sinal\n'
      'Validade: 15 dias',
    );
  });

  test('usa o prazo do orçamento', () {
    final mensagem = montarMensagemWhatsApp(
      orcamento.copyWith(prazoDiasUteis: 30),
    );

    expect(mensagem, contains('Prazo: 30 dias úteis'));
  });

  test('não mostra custos internos (D-16)', () {
    for (final o in orcamentosSeed) {
      final mensagem = montarMensagemWhatsApp(o);
      final custos = o.custosOperacionais;

      // O único valor em reais é o valor final.
      expect(RegExp(r'R\$').allMatches(mensagem), hasLength(1));
      expect(mensagem, contains(formatarMoeda(o.valorFinal)));
      for (final valor in [
        custos.materiaPrima,
        custos.maoDeObra,
        custos.insumos,
        custos.combustivel,
        custos.impostos,
        calcularTotalCustos(custos),
      ]) {
        expect(mensagem, isNot(contains(formatarMoeda(valor))));
      }
      expect(mensagem.toLowerCase(), isNot(contains('custo')));
    }
  });
}
