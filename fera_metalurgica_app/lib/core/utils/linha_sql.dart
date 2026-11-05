import 'package:fera_metalurgica_app/core/domain/endereco.dart';
import 'package:sqflite/sqflite.dart';

// Conversões entre objetos do domínio e linhas do SQLite usadas por mais de
// um repositório (convenções em `core/di/esquema_banco.dart`).

/// Colunas de [endereco] (`logradouro`, `numero`, `bairro`, `cidade`, `uf`,
/// `cep`, `complemento`), para juntar à linha da tabela.
Map<String, Object?> enderecoParaLinha(Endereco endereco) => {
  'logradouro': endereco.logradouro,
  'numero': endereco.numero,
  'bairro': endereco.bairro,
  'cidade': endereco.cidade,
  'uf': endereco.uf,
  'cep': endereco.cep,
  'complemento': endereco.complemento,
};

/// O [Endereco] das colunas de [linha] (inverso de [enderecoParaLinha]).
Endereco enderecoDaLinha(Map<String, Object?> linha) => Endereco(
  logradouro: linha['logradouro']! as String,
  numero: linha['numero']! as String,
  bairro: linha['bairro']! as String,
  cidade: linha['cidade']! as String,
  uf: linha['uf']! as String,
  cep: linha['cep'] as String?,
  complemento: linha['complemento'] as String?,
);

/// Data em microssegundos desde a época, sem perder precisão na volta.
int dataParaLinha(DateTime data) => data.microsecondsSinceEpoch;

/// Inverso de [dataParaLinha], no fuso local.
DateTime dataDaLinha(Object? valor) =>
    DateTime.fromMicrosecondsSinceEpoch(valor! as int);

/// Roda [operacao] numa transação quando [executor] é o banco; se já for
/// uma transação, roda nela (o SQLite não aninha transações). Assim um
/// repositório grava vários registros de forma atômica nos dois casos.
Future<T> emTransacao<T>(
  DatabaseExecutor executor,
  Future<T> Function(DatabaseExecutor executor) operacao,
) => executor is Database ? executor.transaction(operacao) : operacao(executor);
