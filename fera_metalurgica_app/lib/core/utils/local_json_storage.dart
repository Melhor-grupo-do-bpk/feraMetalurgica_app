import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Persists entity lists as local JSON files.
///
/// Each entity type (orçamentos, catálogo, tarefas) owns one file, named by
/// `fileName`, holding a JSON array of maps. This is the single, shared
/// persistence mechanism for the app — feature repositories build on top of
/// this instead of implementing their own file/storage handling.
class LocalJsonStorage {
  /// Creates a [LocalJsonStorage].
  const LocalJsonStorage();

  Future<File> _fileFor(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$fileName.json');
  }

  /// Whether anything was ever written under `fileName` (an empty list
  /// still counts). Used to seed data only on first launch (D-17).
  Future<bool> exists(String fileName) async =>
      (await _fileFor(fileName)).existsSync();

  /// Reads the JSON array stored under `fileName`, or an empty list.
  Future<List<Map<String, dynamic>>> readList(String fileName) async {
    final file = await _fileFor(fileName);
    if (!file.existsSync()) return [];

    final content = await file.readAsString();
    if (content.trim().isEmpty) return [];

    final decoded = jsonDecode(content) as List<dynamic>;
    return decoded.cast<Map<String, dynamic>>();
  }

  /// Overwrites the JSON array stored under `fileName`.
  Future<void> writeList(
    String fileName,
    List<Map<String, dynamic>> items,
  ) async {
    final file = await _fileFor(fileName);
    await file.writeAsString(jsonEncode(items));
  }
}
