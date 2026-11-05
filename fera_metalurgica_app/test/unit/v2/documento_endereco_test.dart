import 'dart:convert';

import 'package:fera_metalurgica_app/core/domain/documento.dart';
import 'package:fera_metalurgica_app/core/domain/endereco.dart';
import 'package:fera_metalurgica_app/core/domain/erro_validacao.dart';
import 'package:fera_metalurgica_app/core/domain/validacao_comum.dart';
import 'package:flutter_test/flutter_test.dart';

const _endereco = Endereco(
  logradouro: 'Rua das Flores',
  numero: '123',
  bairro: 'Centro',
  cidade: 'Curitiba',
  uf: 'PR',
  cep: '80010000',
  complemento: 'Sala 2',
);

void main() {
  group('Documento', () {
    test('normaliza a máscara e deduz o tipo pelos dígitos (D-23)', () {
      final cpf = Documento.deTexto('529.982.247-25');
      expect(cpf.valorNormalizado, '52998224725');
      expect(cpf.tipo, TipoDocumento.cpf);
      expect(cpf.ehPessoaJuridica, isFalse);

      final cnpj = Documento.deTexto('11.222.333/0001-81');
      expect(cnpj.valorNormalizado, '11222333000181');
      expect(cnpj.tipo, TipoDocumento.cnpj);
    });

    test('formata com máscara', () {
      expect(const Documento('52998224725').formatado, '529.982.247-25');
      expect(const Documento('11222333000181').formatado, '11.222.333/0001-81');
    });

    test('CPF e CNPJ válidos não geram erro', () {
      expect(validarDocumento(Documento.deTexto('529.982.247-25')), isEmpty);
      expect(validarDocumento(Documento.deTexto('11444777000161')), isEmpty);
    });

    test('dígito errado, tamanho errado e vazio geram erro', () {
      final cpfErrado = validarDocumento(Documento.deTexto('529.982.247-24'));
      expect(cpfErrado.single.codigo, CodigoErroValidacao.invalido);
      expect(cpfErrado.single.mensagem, 'CPF inválido');
      expect(
        validarDocumento(const Documento('11222333000180')).single.mensagem,
        'CNPJ inválido',
      );
      expect(
        validarDocumento(const Documento('123')).single.codigo,
        CodigoErroValidacao.invalido,
      );
      final vazio = validarDocumento(
        const Documento(''),
        caminho: 'cliente.documento',
      ).single;
      expect(vazio.codigo, CodigoErroValidacao.obrigatorio);
      expect(vazio.caminhoCampo, 'cliente.documento');
    });

    test('JSON é o texto normalizado, preservando zeros à esquerda', () {
      const conversor = DocumentoJsonConverter();
      expect(conversor.toJson(const Documento('01234567890')), '01234567890');
      expect(conversor.fromJson('01234567890').valorNormalizado, '01234567890');
    });
  });

  group('Endereco', () {
    test('formata em uma linha', () {
      expect(
        _endereco.formatado,
        'Rua das Flores, 123, Sala 2 - Centro, Curitiba/PR, CEP 80010-000',
      );
      expect(
        _endereco
            .copyWith(cep: null, complemento: null, numero: 's/n')
            .formatado,
        'Rua das Flores, s/n - Centro, Curitiba/PR',
      );
    });

    test('endereço completo é válido; "s/n" é número aceito', () {
      expect(validarEndereco(_endereco), isEmpty);
      expect(validarEndereco(_endereco.copyWith(numero: 's/n')), isEmpty);
      expect(validarEndereco(_endereco.copyWith(cep: null)), isEmpty);
    });

    test('obrigatórios vazios, UF e CEP inválidos geram erro com caminho', () {
      final erros = validarEndereco(
        const Endereco(
          logradouro: '',
          numero: ' ',
          bairro: '',
          cidade: '',
          uf: 'pr',
          cep: '8001',
        ),
        caminho: 'cliente.endereco',
      );
      expect(erros.map((e) => (e.caminhoCampo, e.codigo)), [
        ('cliente.endereco.logradouro', CodigoErroValidacao.obrigatorio),
        ('cliente.endereco.numero', CodigoErroValidacao.obrigatorio),
        ('cliente.endereco.bairro', CodigoErroValidacao.obrigatorio),
        ('cliente.endereco.cidade', CodigoErroValidacao.obrigatorio),
        ('cliente.endereco.uf', CodigoErroValidacao.invalido),
        ('cliente.endereco.cep', CodigoErroValidacao.invalido),
      ]);
      expect(
        validarEndereco(_endereco.copyWith(uf: '')).single.codigo,
        CodigoErroValidacao.obrigatorio,
      );
      expect(validarEndereco(_endereco.copyWith(uf: 'PRR')), hasLength(1));
    });

    test('JSON de ida e volta', () {
      final json = jsonDecode(jsonEncode(_endereco)) as Map<String, dynamic>;
      expect(Endereco.fromJson(json), _endereco);
    });
  });
}
