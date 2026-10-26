import 'dart:io';

import 'package:fera_metalurgica_app/core/utils/local_json_storage.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory pasta;
  const storage = LocalJsonStorage();

  setUp(() {
    pasta = Directory.systemTemp.createTempSync('fera_storage_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => pasta.path,
        );
  });

  tearDown(() => pasta.deleteSync(recursive: true));

  test('exists só é verdadeiro depois da primeira gravação', () async {
    expect(await storage.exists('tarefas'), isFalse);

    await storage.writeList('tarefas', const []);

    expect(await storage.exists('tarefas'), isTrue);
    expect(await storage.readList('tarefas'), isEmpty);
  });

  test('writeList e readList fazem ida e volta', () async {
    await storage.writeList('orcamentos', [
      {'id': '00001'},
    ]);

    expect(await storage.readList('orcamentos'), [
      {'id': '00001'},
    ]);
  });
}
