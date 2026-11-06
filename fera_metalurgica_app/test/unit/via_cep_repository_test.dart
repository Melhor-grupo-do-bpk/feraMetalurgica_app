import 'dart:io';

import 'package:fera_metalurgica_app/features/clientes/clientes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lê o endereço e consulta o CEP informado', () async {
    late Uri consultado;
    final repositorio = ViaCepRepository((uri) async {
      consultado = uri;
      return '''
      {"cep": "01001-000", "logradouro": "Praça da Sé", "bairro": "Sé",
       "localidade": "São Paulo", "uf": "SP", "ddd": "11"}
      ''';
    });

    expect(
      await repositorio.buscar('01001000'),
      const EnderecoEncontrado(
        logradouro: 'Praça da Sé',
        bairro: 'Sé',
        cidade: 'São Paulo',
        uf: 'SP',
        cep: '01001-000',
      ),
    );
    expect(consultado.toString(), 'https://viacep.com.br/ws/01001000/json/');
  });

  test('CEP geral de cidade vem sem logradouro e bairro', () async {
    final repositorio = ViaCepRepository(
      (_) async =>
          '{"logradouro": "", "bairro": "", "localidade": "Arroio", '
          '"uf": "RS"}',
    );

    final endereco = await repositorio.buscar('95000000');

    expect(endereco?.cidade, 'Arroio');
    expect(endereco?.logradouro, isEmpty);
  });

  test('CEP inexistente devolve null', () async {
    final repositorio = ViaCepRepository((_) async => '{"erro": true}');

    expect(await repositorio.buscar('99999999'), isNull);
  });

  test('a falha de rede chega a quem chamou', () async {
    final repositorio = ViaCepRepository(
      (_) async => throw const SocketException('sem internet'),
    );

    expect(repositorio.buscar('01001000'), throwsA(isA<SocketException>()));
  });
}
