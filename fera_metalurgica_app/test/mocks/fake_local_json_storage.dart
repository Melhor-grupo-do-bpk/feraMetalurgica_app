import 'dart:convert';

import 'package:fera_metalurgica_app/core/utils/local_json_storage.dart';

/// [LocalJsonStorage] em memória, para testar repositórios sem tocar o
/// sistema de arquivos (nem `path_provider`). Guarda o texto JSON, como o
/// arquivo real faria, para exercitar a ida e volta da serialização.
class InMemoryJsonStorage extends LocalJsonStorage {
  final Map<String, String> _arquivos = {};

  @override
  Future<bool> exists(String fileName) async =>
      _arquivos.containsKey(fileName);

  @override
  Future<List<Map<String, dynamic>>> readList(String fileName) async {
    final conteudo = _arquivos[fileName];
    if (conteudo == null) return [];
    return (jsonDecode(conteudo) as List<dynamic>).cast<Map<String, dynamic>>();
  }

  @override
  Future<void> writeList(
    String fileName,
    List<Map<String, dynamic>> items,
  ) async {
    _arquivos[fileName] = jsonEncode(items);
  }
}
