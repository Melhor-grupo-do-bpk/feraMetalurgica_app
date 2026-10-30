import 'dart:io';

import 'package:fera_metalurgica_app/core/di/esquema_banco.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

part 'banco_de_dados.g.dart';

/// Nome do arquivo do banco do app.
const String nomeArquivoBanco = 'fera.db';

/// Banco SQLite do app (D-27), único. Os repositórios recebem este banco
/// (ou uma transação dele) no construtor.
///
/// O banco é aberto antes do `runApp` (ver `abrirBancoDoApp`) e entra pelo
/// override deste provider; nos testes, um banco em memória
/// (`bancoDeTeste()` em `test/mocks/`).
@Riverpod(keepAlive: true)
Database bancoDeDados(Ref ref) => throw UnimplementedError(
  'bancoDeDadosProvider precisa ser sobrescrito com o banco aberto',
);

/// Abre (ou cria) o banco em [caminho] com a [fabrica] dada, já no esquema
/// atual. `novo` indica que o banco acabou de ser criado: o app usa isso
/// para gravar os dados iniciais só no primeiro uso (D-17).
Future<({Database banco, bool novo})> abrirBancoDeDados(
  DatabaseFactory fabrica,
  String caminho,
) async {
  var novo = false;
  final banco = await fabrica.openDatabase(
    caminho,
    options: OpenDatabaseOptions(
      version: versaoEsquema,
      onConfigure: configurarConexao,
      onCreate: (banco, versao) async {
        novo = true;
        await criarEsquema(banco, versao);
      },
      onUpgrade: migrarEsquema,
    ),
  );
  return (banco: banco, novo: novo);
}

/// Abre o banco do app no lugar certo de cada plataforma: a pasta padrão do
/// sqflite no Android e no iOS e, no desktop (Windows), a pasta de suporte
/// do app, pelo `sqflite_common_ffi` (D-27).
Future<({Database banco, bool novo})> abrirBancoDoApp() async {
  final DatabaseFactory fabrica;
  final String pasta;
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    fabrica = databaseFactoryFfi;
    pasta = (await getApplicationSupportDirectory()).path;
  } else {
    fabrica = databaseFactorySqflitePlugin;
    pasta = await fabrica.getDatabasesPath();
  }
  final caminho = '$pasta${Platform.pathSeparator}$nomeArquivoBanco';
  final aberto = await abrirBancoDeDados(fabrica, caminho);
  return aberto;
}
