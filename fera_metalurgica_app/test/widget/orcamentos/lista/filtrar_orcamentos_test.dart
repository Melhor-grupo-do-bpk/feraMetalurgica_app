import 'package:fera_metalurgica_app/features/orcamentos/orcamentos.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/lista/orcamentos_lista_filtro.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../mocks/dados_exemplo.dart';

void main() {
  List<String> ids(String busca, [StatusOrcamento? status]) =>
      filtrarOrcamentos(orcamentosExemplo, (
        busca: busca,
        status: status,
      )).map((o) => o.id).toList();

  test('sem busca nem status devolve tudo, na mesma ordem', () {
    expect(ids(''), orcamentosExemplo.map((o) => o.id).toList());
    expect(ids('   '), hasLength(orcamentosExemplo.length));
  });

  test('filtra por status (D-29)', () {
    expect(ids('', StatusOrcamento.criado), ['orcamento-b', 'orcamento-c']);
    expect(ids('', StatusOrcamento.enviado), ['orcamento-e']);
  });

  test('busca pelo nome sem diferenciar maiúsculas nem acentos', () {
    expect(ids('metalurgica'), ['orcamento-e']);
    expect(ids('METALÚRGICA abc'), ['orcamento-e']);
    expect(ids('joao'), ['orcamento-c']);
    expect(ids('construtora'), ['orcamento-b']);
  });

  test('busca pelo código comparando só os dígitos', () {
    expect(ids('071023-01'), ['orcamento-c']);
    expect(ids('07102301'), ['orcamento-c']);
    expect(ids('081023'), ['orcamento-b']);
  });

  test('busca e status se combinam', () {
    expect(ids('joao', StatusOrcamento.criado), ['orcamento-c']);
    expect(ids('joao', StatusOrcamento.enviado), isEmpty);
  });

  test('busca sem resultado devolve lista vazia', () {
    expect(ids('inexistente'), isEmpty);
    expect(ids('99999'), isEmpty);
  });
}
