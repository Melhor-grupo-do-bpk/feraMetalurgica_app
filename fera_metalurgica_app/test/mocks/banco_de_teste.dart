import 'package:fera_metalurgica_app/core/di/banco_de_dados.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Banco SQLite novo, em memória e no esquema atual, para testes de
/// repositório e de widget (D-27).
///
/// Usa o `databaseFactoryFfiNoIsolate`: sem isolate, as consultas avançam
/// dentro do tempo simulado do `testWidgets`. Cada chamada devolve um banco
/// independente; feche com `banco.close()` no `tearDown`.
Future<Database> bancoDeTeste() async {
  sqfliteFfiInit();
  final (:banco, novo: _) = await abrirBancoDeDados(
    databaseFactoryFfiNoIsolate,
    inMemoryDatabasePath,
  );
  return banco;
}
