import 'package:sqflite/sqflite.dart';

/// Valor da preferência [chave] (tabela `preferencias`), ou `null` se nunca
/// foi gravada.
Future<String?> lerPreferencia(DatabaseExecutor banco, String chave) async {
  final linhas = await banco.query(
    'preferencias',
    columns: ['valor'],
    where: 'chave = ?',
    whereArgs: [chave],
  );
  return linhas.isEmpty ? null : linhas.single['valor']! as String;
}

/// Grava [valor] na preferência [chave], trocando o anterior.
Future<void> salvarPreferencia(
  DatabaseExecutor banco,
  String chave,
  String valor,
) => banco.insert('preferencias', {
  'chave': chave,
  'valor': valor,
}, conflictAlgorithm: ConflictAlgorithm.replace);
