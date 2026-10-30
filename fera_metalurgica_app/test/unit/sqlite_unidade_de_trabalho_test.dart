import 'package:fera_metalurgica_app/features/orcamentos/data/sqlite_orcamento_repository.dart';
import 'package:fera_metalurgica_app/features/orcamentos/data/sqlite_unidade_de_trabalho.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../mocks/banco_de_teste.dart';
import 'v2/dados_v2.dart';

void main() {
  late Database banco;
  late SqliteUnidadeDeTrabalho unidade;
  final dia = DateTime(2026, 10, 28);

  setUp(() async {
    banco = await bancoDeTeste();
    unidade = SqliteUnidadeDeTrabalho(banco);
  });
  tearDown(() => banco.close());

  test('confirma tudo o que a operação gravou', () async {
    final sequencia = await unidade.executarEmTransacao((repos) async {
      await repos.clientes.salvar(clienteTeste);
      await repos.orcamentos.inserir(orcamentoSalvo(edicaoC));
      return await repos.sequencias.proximaDoDia(dia);
    });

    expect(sequencia, 1);
    expect(
      await SqliteOrcamentoRepository(banco).listarResumos(),
      hasLength(1),
    );
    expect(await banco.query('clientes'), hasLength(1));
  });

  test('um erro desfaz tudo, inclusive a sequência, e é relançado', () async {
    await expectLater(
      unidade.executarEmTransacao((repos) async {
        await repos.sequencias.proximaDoDia(dia);
        await repos.clientes.salvar(clienteTeste);
        await repos.orcamentos.inserir(orcamentoSalvo(edicaoC));
        throw StateError('falha simulada');
      }),
      throwsA(isA<StateError>()),
    );

    expect(await SqliteOrcamentoRepository(banco).listarResumos(), isEmpty);
    expect(await banco.query('clientes'), isEmpty);
    final proxima = await unidade.executarEmTransacao(
      (repos) => repos.sequencias.proximaDoDia(dia),
    );
    expect(proxima, 1);
  });
}
