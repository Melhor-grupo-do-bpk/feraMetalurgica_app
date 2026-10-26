import 'package:fera_metalurgica_app/features/orcamentos/orcamentos.dart';
import 'package:fera_metalurgica_app/features/orcamentos/presentation/lista/orcamentos_lista_filtro.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  List<String> ids(String busca, [StatusOrcamento? status]) =>
      filtrarOrcamentos(orcamentosSeed, (
        busca: busca,
        status: status,
      )).map((o) => o.id).toList();

  test('sem busca nem status devolve tudo, na mesma ordem', () {
    expect(ids(''), orcamentosSeed.map((o) => o.id).toList());
    expect(ids('   '), hasLength(orcamentosSeed.length));
  });

  test('filtra por status', () {
    expect(ids('', StatusOrcamento.rascunho), ['00480']);
    expect(ids('', StatusOrcamento.emAnalise), ['00482']);
    expect(ids('', StatusOrcamento.recusado), ['00478']);
  });

  test('busca pelo nome sem diferenciar maiúsculas nem acentos', () {
    expect(ids('metalurgica'), ['00481']);
    expect(ids('METALÚRGICA abc'), ['00481']);
    expect(ids('joao'), ['00482']);
    expect(ids('construtora'), ['00480', '00479']);
  });

  test('busca pelo número comparando só os dígitos', () {
    expect(ids('00479'), ['00479']);
    expect(ids('#00479'), ['00479']);
    expect(ids('481'), ['00481']);
  });

  test('busca e status se combinam', () {
    expect(ids('construtora', StatusOrcamento.enviado), ['00479']);
    expect(ids('joao', StatusOrcamento.aprovado), isEmpty);
  });

  test('busca sem resultado devolve lista vazia', () {
    expect(ids('inexistente'), isEmpty);
    expect(ids('99999'), isEmpty);
  });
}
