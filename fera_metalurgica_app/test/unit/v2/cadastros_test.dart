import 'dart:convert';

import 'package:fera_metalurgica_app/core/domain/dinheiro.dart';
import 'package:fera_metalurgica_app/core/domain/documento.dart';
import 'package:fera_metalurgica_app/core/domain/erro_validacao.dart';
import 'package:fera_metalurgica_app/features/clientes/clientes.dart';
import 'package:fera_metalurgica_app/features/empresa/empresa.dart';
import 'package:fera_metalurgica_app/features/materiais/materiais.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dados_v2.dart';

List<(String, CodigoErroValidacao)> _resumo(List<ErroValidacao> erros) =>
    erros.map((e) => (e.caminhoCampo, e.codigo)).toList();

void main() {
  group('Material', () {
    test('nasce ativo', () {
      expect(granito.ativo, isTrue);
    });

    test('válido sem erros; nome vazio e preço não positivo geram erro', () {
      expect(validarMaterial(granito), isEmpty);
      expect(
        _resumo(
          validarMaterial(
            granito.copyWith(nome: '  ', precoReferencia: Dinheiro.zero),
          ),
        ),
        [
          ('nome', CodigoErroValidacao.obrigatorio),
          ('precoReferencia', CodigoErroValidacao.naoPositivo),
        ],
      );
    });

    test('JSON: unidade pelo nome e preço em centavos', () {
      final json = jsonDecode(jsonEncode(madeira)) as Map<String, dynamic>;
      expect(json['unidade'], 'm3');
      expect(json['precoReferencia'], 350000);
      expect(Material.fromJson(json), madeira);
    });
  });

  group('Empresa', () {
    test('completa quando todos os obrigatórios são válidos', () {
      expect(empresaTeste.estaCompleta, isTrue);
      expect(validarEmpresa(empresaTeste), isEmpty);
      expect(empresaTeste.copyWith(email: null).estaCompleta, isTrue);
    });

    test('incompleta com obrigatório vazio ou inválido', () {
      final incompleta = empresaTeste.copyWith(
        nomeRazaoSocial: '',
        documento: const Documento('11222333000180'),
        telefone: '123',
        email: 'sem-arroba',
      );
      expect(incompleta.estaCompleta, isFalse);
      expect(_resumo(validarEmpresa(incompleta)), [
        ('nomeRazaoSocial', CodigoErroValidacao.obrigatorio),
        ('documento', CodigoErroValidacao.invalido),
        ('telefone', CodigoErroValidacao.invalido),
        ('email', CodigoErroValidacao.invalido),
      ]);
      expect(
        empresaTeste
            .copyWith(endereco: enderecoTeste.copyWith(uf: 'pr'))
            .estaCompleta,
        isFalse,
      );
    });

    test('JSON de ida e volta, com documento em texto', () {
      final json = jsonDecode(jsonEncode(empresaTeste)) as Map<String, dynamic>;
      expect(json['documento'], '11222333000181');
      expect(Empresa.fromJson(json), empresaTeste);
    });
  });

  group('Cliente', () {
    test('válido sem erros', () {
      expect(validarCliente(clienteTeste), isEmpty);
    });

    test('obrigatórios vazios geram erro com o caminho pedido', () {
      final erros = validarCliente(
        clienteTeste.copyWith(
          nome: '',
          documento: const Documento(''),
          celular: '',
          endereco: enderecoTeste.copyWith(cidade: ''),
        ),
        caminho: 'cliente',
      );
      expect(_resumo(erros), [
        ('cliente.nome', CodigoErroValidacao.obrigatorio),
        ('cliente.documento', CodigoErroValidacao.obrigatorio),
        ('cliente.celular', CodigoErroValidacao.obrigatorio),
        ('cliente.endereco.cidade', CodigoErroValidacao.obrigatorio),
      ]);
    });

    test('JSON de ida e volta', () {
      final json = jsonDecode(jsonEncode(clienteTeste)) as Map<String, dynamic>;
      expect(Cliente.fromJson(json), clienteTeste);
    });
  });
}
