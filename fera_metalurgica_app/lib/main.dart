import 'package:fera_metalurgica_app/core/constants/app_constants.dart';
import 'package:fera_metalurgica_app/core/di/banco_de_dados.dart';
import 'package:fera_metalurgica_app/core/di/local_storage_provider.dart';
import 'package:fera_metalurgica_app/core/di/relogio_provider.dart';
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
  final (:banco, :novo) = await abrirBancoDoApp();
  final container = ProviderContainer(
    overrides: [bancoDeDadosProvider.overrideWithValue(banco)],
  );
  await popularDadosIniciais(
    container,
    bancoNovo: novo,
    incluirExemplos: kDebugMode,
  );
  runApp(
    UncontrolledProviderScope(container: container, child: const FeraApp()),
  );
}

/// Grava os dados iniciais na primeira execução (D-17): o catálogo sempre
/// (é o catálogo real da empresa) e, se [incluirExemplos] (o app passa
/// `kDebugMode`), os orçamentos e tarefas de exemplo, com as datas a partir
/// do `agoraProvider`.
///
/// Os exemplos do banco só entram quando ele acabou de ser criado
/// ([bancoNovo]); os arquivos JSON, quando nunca foram gravados. Assim,
/// apagar tudo pelo app não traz os exemplos de volta.
Future<void> popularDadosIniciais(
  ProviderContainer container, {
  required bool bancoNovo,
  required bool incluirExemplos,
}) async {
  final storage = container.read(localJsonStorageProvider);
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
  if (!bancoNovo) return;
  final tarefas = container.read(tarefaRepositoryProvider);
  for (final tarefa in cronogramaSeed(container.read(agoraProvider))) {
    await tarefas.save(tarefa);
  }
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
