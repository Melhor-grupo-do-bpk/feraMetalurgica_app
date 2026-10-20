import 'package:fera_metalurgica_app/core/constants/app_constants.dart';
import 'package:fera_metalurgica_app/core/router/app_router.dart';
import 'package:fera_metalurgica_app/core/theme/app_theme.dart';
import 'package:fera_metalurgica_app/core/utils/local_json_storage.dart';
import 'package:fera_metalurgica_app/features/catalogo/catalogo.dart';
import 'package:fera_metalurgica_app/features/cronograma/cronograma.dart';
import 'package:fera_metalurgica_app/features/orcamentos/orcamentos.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await popularDadosIniciais(
    const LocalJsonStorage(),
    incluirExemplos: kDebugMode,
  );
  runApp(const ProviderScope(child: FeraApp()));
}

/// Grava os dados iniciais na primeira execução (D-17): o catálogo sempre
/// (é o catálogo real da empresa) e, se [incluirExemplos] (o app passa
/// `kDebugMode`), os orçamentos e tarefas de exemplo. Cada arquivo só é
/// semeado se nunca foi gravado, então apagar tudo pelo app não traz os
/// exemplos de volta.
Future<void> popularDadosIniciais(
  LocalJsonStorage storage, {
  required bool incluirExemplos,
}) async {
  await _semear(
    storage,
    AppConstants.catalogoFileName,
    catalogoSeed,
    LocalCatalogoRepository(storage).save,
  );
  if (!incluirExemplos) return;
  await _semear(
    storage,
    AppConstants.orcamentosFileName,
    orcamentosSeed,
    LocalOrcamentoRepository(storage).save,
  );
  await _semear(
    storage,
    AppConstants.tarefasFileName,
    cronogramaSeed,
    LocalCronogramaRepository(storage).save,
  );
}

Future<void> _semear<T>(
  LocalJsonStorage storage,
  String fileName,
  List<T> itens,
  Future<void> Function(T) salvar,
) async {
  if (await storage.exists(fileName)) return;
  for (final item in itens) {
    await salvar(item);
  }
}

/// Widget raiz do app FERA.
class FeraApp extends StatelessWidget {
  /// Cria o widget raiz do app.
  const FeraApp({this.themeMode = ThemeMode.system, super.key});

  /// Tema claro/escuro; por padrão segue o sistema.
  final ThemeMode themeMode;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'FERA',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: appRouter,
    );
  }
}
