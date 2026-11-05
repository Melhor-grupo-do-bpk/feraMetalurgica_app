import 'package:fera_metalurgica_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../mocks/container_de_teste.dart';

/// [FeraApp] completo para testes de navegação, como o app em modo debug
/// (`overridesDeTeste`): banco em memória já semeado com os dados de
/// exemplo. Assim as telas reais carregam dados em vez de ficar presas no
/// carregamento. Com [agora], fixa o `agoraProvider`; com [semEmpresa],
/// começa sem a empresa emitente.
Future<Widget> feraAppDeTeste({
  ThemeMode themeMode = ThemeMode.system,
  DateTime? agora,
  bool semEmpresa = false,
}) async => ProviderScope(
  overrides: await overridesDeTeste(agora: agora, semEmpresa: semEmpresa),
  child: FeraApp(themeMode: themeMode),
);
