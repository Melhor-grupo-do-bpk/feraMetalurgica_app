import 'package:fera_metalurgica_app/core/di/local_storage_provider.dart';
import 'package:fera_metalurgica_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../mocks/fake_local_json_storage.dart';

/// [FeraApp] completo para testes de navegação: o armazenamento é um
/// [InMemoryJsonStorage] (sem `path_provider`) já semeado com os dados de
/// exemplo, como o app em modo debug. Assim as telas reais (não só os
/// stubs da F1) carregam dados em vez de ficar presas no carregamento.
Future<Widget> feraAppDeTeste({ThemeMode themeMode = ThemeMode.system}) async {
  final storage = InMemoryJsonStorage();
  await popularDadosIniciais(storage, incluirExemplos: true);
  return ProviderScope(
    overrides: [localJsonStorageProvider.overrideWithValue(storage)],
    child: FeraApp(themeMode: themeMode),
  );
}
