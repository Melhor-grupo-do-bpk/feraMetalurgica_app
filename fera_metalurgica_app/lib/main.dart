import 'package:fera_metalurgica_app/core/constants/app_constants.dart';
import 'package:fera_metalurgica_app/core/di/banco_de_dados.dart';
import 'package:fera_metalurgica_app/core/di/local_storage_provider.dart';
import 'package:fera_metalurgica_app/core/di/relogio_provider.dart';
import 'package:fera_metalurgica_app/core/router/app_router.dart';
import 'package:fera_metalurgica_app/core/theme/app_theme.dart';
import 'package:fera_metalurgica_app/core/utils/id_generator.dart';
import 'package:fera_metalurgica_app/core/utils/local_json_storage.dart';
import 'package:fera_metalurgica_app/features/catalogo/catalogo.dart';
import 'package:fera_metalurgica_app/features/cronograma/cronograma.dart';
import 'package:fera_metalurgica_app/features/empresa/empresa.dart';
import 'package:fera_metalurgica_app/features/materiais/materiais.dart';
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
/// `kDebugMode`), os exemplos: a empresa, um material de cada unidade, os
/// orçamentos C (A + B) e B, e tarefas de hoje e de amanhã (HO-T8-01).
///
/// As datas saem do `agoraProvider`. Os orçamentos são gravados pelo
/// `FinalizarOrcamentoService` em dias anteriores (anteontem e ontem), para
/// que o primeiro orçamento do dia seja o `-01`.
///
/// Os exemplos do banco só entram quando ele acabou de ser criado
/// ([bancoNovo]), e o catálogo, quando o arquivo nunca foi gravado. Assim,
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
  if (!bancoNovo) return;

  final agora = container.read(agoraProvider);
  await container.read(empresaRepositoryProvider).salvar(empresaExemplo);
  final materiais = container.read(materialRepositoryProvider);
  for (final material in materiaisExemplo) {
    await materiais.salvar(material);
  }

  DateTime diaAnterior(int dias, int hora) =>
      DateTime(agora.year, agora.month, agora.day - dias, hora);
  Future<Orcamento> gravar(OrcamentoEmEdicao edicao, DateTime quando) =>
      FinalizarOrcamentoService(
        unidadeDeTrabalho: container.read(unidadeDeTrabalhoProvider),
        relogio: () => quando,
        gerarId: gerarId,
      ).executar(edicao);
  final orcamentoC = await gravar(edicaoExemploC(gerarId), diaAnterior(2, 10));
  await gravar(edicaoExemploB(gerarId), diaAnterior(1, 15));

  final tarefas = container.read(tarefaRepositoryProvider);
  final exemplos = cronogramaSeed(
    agora,
    orcamentoId: orcamentoC.id,
    codigoOrcamento: orcamentoC.codigoExibicao,
  );
  for (final tarefa in exemplos) {
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
