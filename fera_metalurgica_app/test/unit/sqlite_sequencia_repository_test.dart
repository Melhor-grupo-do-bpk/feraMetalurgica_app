import 'package:fera_metalurgica_app/features/orcamentos/data/sqlite_sequencia_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../mocks/banco_de_teste.dart';

void main() {
  late Database banco;
  late SqliteSequenciaRepository repositorio;

  setUp(() async {
    banco = await bancoDeTeste();
    repositorio = SqliteSequenciaRepository(banco);
  });
  tearDown(() => banco.close());

  test('começa em 1 e cresce no mesmo dia, sem importar a hora', () async {
    expect(await repositorio.proximaDoDia(DateTime(2026, 10, 28, 8)), 1);
    expect(await repositorio.proximaDoDia(DateTime(2026, 10, 28, 12, 30)), 2);
    expect(await repositorio.proximaDoDia(DateTime(2026, 10, 28, 23, 59)), 3);
  });

  test('a virada do dia reinicia a contagem do dia novo', () async {
    final antes = DateTime(2026, 10, 28, 23, 59, 59, 999);
    final depois = antes.add(const Duration(milliseconds: 1));
    expect(depois, DateTime(2026, 10, 29));

    expect(await repositorio.proximaDoDia(antes), 1);
    expect(await repositorio.proximaDoDia(depois), 1);
    expect(await repositorio.proximaDoDia(antes), 2);
    expect(await repositorio.proximaDoDia(depois), 2);
  });

  test('a virada do mês e do ano também separa os dias', () async {
    expect(await repositorio.proximaDoDia(DateTime(2026, 12, 31, 23)), 1);
    expect(await repositorio.proximaDoDia(DateTime(2027)), 1);
    expect(await repositorio.proximaDoDia(DateTime(2026, 12, 31)), 2);
  });

  test('a chave do dia é a data local em AAAA-MM-DD', () {
    expect(
      SqliteSequenciaRepository.chaveDoDia(DateTime(2026, 3, 7, 23, 59)),
      '2026-03-07',
    );
  });

  test('o contador nunca volta atrás, mesmo sem orçamentos', () async {
    final dia = DateTime(2026, 10, 28);
    await repositorio.proximaDoDia(dia);
    await repositorio.proximaDoDia(dia);
    await banco.delete('orcamentos');
    expect(await repositorio.proximaDoDia(dia), 3);
  });
}
