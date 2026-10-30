import 'package:fera_metalurgica_app/core/domain/dinheiro.dart';
import 'package:fera_metalurgica_app/features/materiais/materiais.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../mocks/banco_de_teste.dart';
import 'v2/dados_v2.dart';

void main() {
  late Database banco;
  late SqliteMaterialRepository repositorio;

  setUp(() async {
    banco = await bancoDeTeste();
    repositorio = SqliteMaterialRepository(banco);
  });
  tearDown(() => banco.close());

  test('salva e lê de volta o material, com unidade e preço', () async {
    await repositorio.salvar(madeira);
    expect(await repositorio.buscarPorId(madeira.id), madeira);
    expect(await repositorio.buscarPorId('inexistente'), isNull);
  });

  test('salvar de novo atualiza o mesmo material', () async {
    await repositorio.salvar(mdf);
    final novo = mdf.copyWith(precoReferencia: Dinheiro.parse('100,00'));
    await repositorio.salvar(novo);
    expect(await repositorio.listarTodos(), [novo]);
  });

  test('lista ordenada por nome, sem diferenciar maiúsculas', () async {
    final minusculo = granito.copyWith(id: 'g2', nome: 'azulejo');
    for (final m in [mdf, granito, madeira, minusculo]) {
      await repositorio.salvar(m);
    }
    expect((await repositorio.listarTodos()).map((m) => m.nome), [
      'azulejo',
      granito.nome,
      madeira.nome,
      mdf.nome,
    ]);
  });

  test('inativar tira das seleções; reativar devolve', () async {
    for (final m in [mdf, granito, madeira]) {
      await repositorio.salvar(m);
    }
    await repositorio.inativar(granito.id);

    expect(await repositorio.listarAtivos(), [madeira, mdf]);
    expect(await repositorio.listarTodos(), [
      granito.copyWith(ativo: false),
      madeira,
      mdf,
    ]);

    await repositorio.reativar(granito.id);
    expect(await repositorio.listarAtivos(), [granito, madeira, mdf]);
  });

  test(
    'filtro dos ativos por parte do nome, sem diferenciar maiúsculas',
    () async {
      for (final m in [mdf, granito, madeira]) {
        await repositorio.salvar(m);
      }
      expect(await repositorio.listarAtivos(filtro: 'GRAN'), [granito]);
      expect(await repositorio.listarAtivos(filtro: '  '), hasLength(3));
    },
  );
}
