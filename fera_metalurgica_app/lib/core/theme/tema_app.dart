import 'package:fera_metalurgica_app/core/di/banco_de_dados.dart';
import 'package:fera_metalurgica_app/core/di/preferencias.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sqflite/sqflite.dart';

part 'tema_app.g.dart';

const String _chaveTema = 'tema';

/// Tema salvo no aparelho (D-45). Sem escolha, o app segue o sistema.
Future<ThemeMode> lerTemaSalvo(DatabaseExecutor banco) async =>
    switch (await lerPreferencia(banco, _chaveTema)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

/// Tema com que o app abre: o `main` o lê do banco antes do `runApp`, para
/// a primeira tela já sair no tema certo.
@Riverpod(keepAlive: true)
ThemeMode temaInicial(Ref ref) => ThemeMode.system;

/// Tema do app, trocado pelo botão da `AppTopBar` (D-45).
@Riverpod(keepAlive: true)
class TemaApp extends _$TemaApp {
  @override
  ThemeMode build() => ref.watch(temaInicialProvider);

  /// Troca para o tema oposto ao [atual] (o que está na tela) e o salva.
  Future<void> alternar({required Brightness atual}) async {
    final novo = atual == Brightness.dark ? ThemeMode.light : ThemeMode.dark;
    state = novo;
    await salvarPreferencia(
      ref.read(bancoDeDadosProvider),
      _chaveTema,
      novo.name,
    );
  }
}
