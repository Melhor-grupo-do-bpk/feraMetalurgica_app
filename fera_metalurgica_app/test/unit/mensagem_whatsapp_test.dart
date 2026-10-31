import 'package:fera_metalurgica_app/features/orcamentos/domain/mensagem_whatsapp.dart';
import 'package:flutter_test/flutter_test.dart';

import '../mocks/dados_exemplo.dart';

void main() {
  test('monta o resumo do exemplo C, com a validade (D-15)', () {
    expect(
      montarMensagemWhatsApp(orcamentoExemploC),
      'Olá, João da Silva! Segue o resumo do orçamento Nº 071023-01 da '
      'Fera Metalúrgica Ltda.\n'
      '\n'
      'Valor total: R\$ 3.630,80\n'
      'Validade: até 22/10/2023',
    );
  });

  test('sem validade, não mostra a linha', () {
    final mensagem = montarMensagemWhatsApp(orcamentoExemploB);

    expect(mensagem, endsWith(r'Valor total: R$ 644,40'));
    expect(mensagem, isNot(contains('Validade')));
  });

  test('a partir da 2ª revisão, mostra "rev. N" (D-30)', () {
    final mensagem = montarMensagemWhatsApp(
      orcamentoExemploB.copyWith(revisao: 2),
    );

    expect(mensagem, contains('Nº 081023-01 rev. 2'));
  });

  test('só o total geral, sem custos nem adicionais (D-39)', () {
    final mensagem = montarMensagemWhatsApp(orcamentoExemploC);

    // O único valor em reais é o total geral.
    expect(RegExp(r'R\$').allMatches(mensagem), hasLength(1));
    expect(mensagem.toLowerCase(), isNot(contains('custo')));
    expect(mensagem.toLowerCase(), isNot(contains('desconto')));
  });
}
