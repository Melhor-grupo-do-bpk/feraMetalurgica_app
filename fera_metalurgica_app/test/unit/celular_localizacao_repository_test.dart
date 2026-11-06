import 'package:fera_metalurgica_app/features/clientes/clientes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';

void main() {
  Future<EnderecoEncontrado> enderecoDe(Placemark? lugar) =>
      CelularLocalizacaoRepository(() async => lugar).enderecoAtual();

  test('lê rua, bairro, cidade, UF e CEP completo', () async {
    final endereco = await enderecoDe(
      const Placemark(
        thoroughfare: 'Avenida Ipiranga',
        subLocality: 'Azenha',
        locality: 'Porto Alegre',
        administrativeArea: 'Rio Grande do Sul',
        postalCode: '90160-093',
      ),
    );

    expect(
      endereco,
      const EnderecoEncontrado(
        logradouro: 'Avenida Ipiranga',
        bairro: 'Azenha',
        cidade: 'Porto Alegre',
        uf: 'RS',
        cep: '90160093',
      ),
    );
  });

  test('sem locality, a cidade vem da área administrativa menor', () async {
    final endereco = await enderecoDe(
      const Placemark(thoroughfare: 'Rua A', subAdministrativeArea: 'Canoas'),
    );

    expect(endereco.cidade, 'Canoas');
  });

  test('entende a UF como sigla ou com prefixo e acento', () async {
    Future<String> uf(String area) async => (await enderecoDe(
      Placemark(locality: 'Cidade', administrativeArea: area),
    )).uf;

    expect(await uf('SP'), 'SP');
    expect(await uf('São Paulo'), 'SP');
    expect(await uf('State of São Paulo'), 'SP');
    expect(await uf('Estado do Paraná'), 'PR');
    expect(await uf('Federal District'), 'DF');
    expect(await uf('Lugar nenhum'), isEmpty);
  });

  test('ignora o CEP parcial', () async {
    final endereco = await enderecoDe(
      const Placemark(locality: 'Porto Alegre', postalCode: '90010'),
    );

    expect(endereco.cep, isEmpty);
  });

  test('sem lugar ou sem rua e cidade, falha com semEndereco', () async {
    final falha = isA<FalhaLocalizacao>().having(
      (f) => f.motivo,
      'motivo',
      MotivoFalhaLocalizacao.semEndereco,
    );

    expect(enderecoDe(null), throwsA(falha));
    expect(enderecoDe(const Placemark(country: 'Brasil')), throwsA(falha));
  });
}
