import 'package:fera_metalurgica_app/core/domain/documento.dart';
import 'package:fera_metalurgica_app/features/clientes/clientes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../mocks/banco_de_teste.dart';
import 'v2/dados_v2.dart';

final Cliente _empresaCliente = clienteTeste.copyWith(
  id: 'cliente-2',
  nome: 'Ácme Indústria',
  documento: const Documento('11222333000181'),
  celular: '(11) 98888-7777',
);

void main() {
  late Database banco;
  late SqliteClienteRepository repositorio;

  setUp(() async {
    banco = await bancoDeTeste();
    repositorio = SqliteClienteRepository(banco);
  });
  tearDown(() => banco.close());

  test('salva e busca pelo documento normalizado', () async {
    await repositorio.salvar(clienteTeste);
    expect(
      await repositorio.buscarPorDocumento(Documento.deTexto('529.982.247-25')),
      clienteTeste,
    );
    expect(
      await repositorio.buscarPorDocumento(const Documento('00000000000')),
      isNull,
    );
  });

  test('salvar de novo atualiza o mesmo cliente', () async {
    await repositorio.salvar(clienteTeste);
    final novo = clienteTeste.copyWith(nome: 'João S.');
    await repositorio.salvar(novo);
    expect(await repositorio.pesquisar(''), [novo]);
  });

  test('documento de outro cliente viola a unicidade', () async {
    await repositorio.salvar(clienteTeste);
    expect(
      () => repositorio.salvar(clienteTeste.copyWith(id: 'outro')),
      throwsA(isA<DatabaseException>()),
    );
  });

  group('pesquisar', () {
    setUp(() async {
      await repositorio.salvar(clienteTeste);
      await repositorio.salvar(_empresaCliente);
    });

    test('termo vazio devolve todos, ordenados por nome', () async {
      expect(await repositorio.pesquisar(' '), [_empresaCliente, clienteTeste]);
    });

    test('pelo nome, sem diferenciar maiúsculas', () async {
      expect(await repositorio.pesquisar('ÁCME'), [_empresaCliente]);
      expect(await repositorio.pesquisar('silva'), [clienteTeste]);
    });

    test('pelo documento ou celular, só pelos dígitos', () async {
      expect(await repositorio.pesquisar('11.222.333'), [_empresaCliente]);
      expect(await repositorio.pesquisar('99999-8888'), [clienteTeste]);
    });

    test('sem resultado', () async {
      expect(await repositorio.pesquisar('Maria'), isEmpty);
    });
  });
}
