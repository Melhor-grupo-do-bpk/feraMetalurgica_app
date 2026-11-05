import 'package:fera_metalurgica_app/features/empresa/empresa.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../mocks/banco_de_teste.dart';
import 'v2/dados_v2.dart';

void main() {
  late Database banco;
  late SqliteEmpresaRepository repositorio;

  setUp(() async {
    banco = await bancoDeTeste();
    repositorio = SqliteEmpresaRepository(banco);
  });
  tearDown(() => banco.close());

  test('sem cadastro, obter devolve null', () async {
    expect(await repositorio.obter(), isNull);
  });

  test('salva e lê de volta, com endereço e e-mail', () async {
    await repositorio.salvar(empresaTeste);
    expect(await repositorio.obter(), empresaTeste);
  });

  test('e-mail e campos opcionais do endereço podem ficar vazios', () async {
    final semOpcionais = empresaTeste.copyWith(
      email: null,
      endereco: empresaTeste.endereco.copyWith(cep: null),
    );
    await repositorio.salvar(semOpcionais);
    expect(await repositorio.obter(), semOpcionais);
  });

  test('guarda um emitente só, mesmo com outro id', () async {
    await repositorio.salvar(empresaTeste);
    final outra = empresaTeste.copyWith(id: 'empresa-2', nomeRazaoSocial: 'B');
    await repositorio.salvar(outra);

    expect(await repositorio.obter(), outra);
    expect(await banco.query('empresa'), hasLength(1));
  });

  test('dentro de uma transação, também substitui', () async {
    await repositorio.salvar(empresaTeste);
    final outra = empresaTeste.copyWith(id: 'empresa-2');
    await banco.transaction(
      (txn) => SqliteEmpresaRepository(txn).salvar(outra),
    );
    expect(await repositorio.obter(), outra);
  });
}
