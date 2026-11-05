import 'package:fera_metalurgica_app/features/orcamentos/domain/mensagem_whatsapp.dart';
import 'package:flutter_test/flutter_test.dart';

import '../mocks/dados_exemplo.dart';

void main() {
  test('monta o texto que acompanha o PDF (D-43)', () {
    expect(
      montarMensagemWhatsApp(orcamentoExemploC),
      'Olá, João da Silva! Segue o orçamento Nº 071023-01 da '
      'Fera Metalúrgica Ltda.',
    );
  });

  test('a partir da 2ª revisão, mostra "rev. N" (D-30)', () {
    final mensagem = montarMensagemWhatsApp(
      orcamentoExemploB.copyWith(revisao: 2),
    );

    expect(mensagem, contains('Nº 081023-01 rev. 2'));
  });

  test('sem valores: eles ficam no PDF (D-39)', () {
    expect(montarMensagemWhatsApp(orcamentoExemploC), isNot(contains(r'R$')));
  });
}
