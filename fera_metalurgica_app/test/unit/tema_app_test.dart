import 'package:fera_metalurgica_app/core/di/banco_de_dados.dart';
import 'package:fera_metalurgica_app/core/di/preferencias.dart';
import 'package:fera_metalurgica_app/core/theme/tema_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../mocks/banco_de_teste.dart';

void main() {
  late Database banco;

  setUp(() async => banco = await bancoDeTeste());
  tearDown(() => banco.close());

  test('sem escolha, segue o sistema', () async {
    expect(await lerTemaSalvo(banco), ThemeMode.system);
  });

  test('preferência gravada é lida de volta e pode ser trocada', () async {
    expect(await lerPreferencia(banco, 'x'), isNull);
    await salvarPreferencia(banco, 'x', 'a');
    await salvarPreferencia(banco, 'x', 'b');
    expect(await lerPreferencia(banco, 'x'), 'b');
  });

  test('alternar troca para o oposto do tema na tela e salva', () async {
    final container = ProviderContainer(
      overrides: [bancoDeDadosProvider.overrideWithValue(banco)],
    );
    addTearDown(container.dispose);
    final tema = container.read(temaAppProvider.notifier);

    await tema.alternar(atual: Brightness.light);
    expect(container.read(temaAppProvider), ThemeMode.dark);
    expect(await lerTemaSalvo(banco), ThemeMode.dark);

    await tema.alternar(atual: Brightness.dark);
    expect(container.read(temaAppProvider), ThemeMode.light);
    expect(await lerTemaSalvo(banco), ThemeMode.light);
  });

  test('abre com o tema inicial lido pelo main', () {
    final container = ProviderContainer(
      overrides: [temaInicialProvider.overrideWithValue(ThemeMode.dark)],
    );
    addTearDown(container.dispose);

    expect(container.read(temaAppProvider), ThemeMode.dark);
  });
}
