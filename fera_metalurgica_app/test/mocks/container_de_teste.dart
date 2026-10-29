import 'package:fera_metalurgica_app/core/di/banco_de_dados.dart';
import 'package:fera_metalurgica_app/core/di/local_storage_provider.dart';
import 'package:fera_metalurgica_app/core/di/relogio_provider.dart';
import 'package:fera_metalurgica_app/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'banco_de_teste.dart';
import 'fake_local_json_storage.dart';

/// Overrides do app em modo debug: banco SQLite novo, em memória, com os
/// dados de exemplo já gravados por `popularDadosIniciais`. Com [agora],
/// fixa o `agoraProvider` (e as datas dos exemplos).
///
/// Chame dentro de um teste ou de um `setUp`: o banco é fechado no fim do
/// teste.
Future<List<Override>> overridesDeTeste({DateTime? agora}) async {
  final banco = await bancoDeTeste();
  addTearDown(banco.close);
  final overrides = [
    bancoDeDadosProvider.overrideWithValue(banco),
    localJsonStorageProvider.overrideWithValue(InMemoryJsonStorage()),
    if (agora != null) agoraProvider.overrideWithValue(agora),
  ];
  final semeador = ProviderContainer(overrides: overrides);
  try {
    await popularDadosIniciais(
      semeador,
      bancoNovo: true,
      incluirExemplos: true,
    );
  } finally {
    semeador.dispose();
  }
  return overrides;
}

/// [ProviderContainer] com os [overridesDeTeste], descartado no fim do
/// teste.
Future<ProviderContainer> containerDeTeste({DateTime? agora}) async {
  final container = ProviderContainer(
    overrides: await overridesDeTeste(agora: agora),
  );
  addTearDown(container.dispose);
  return container;
}
