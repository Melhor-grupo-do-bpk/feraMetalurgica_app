import 'package:fera_metalurgica_app/core/di/banco_de_dados.dart';
import 'package:fera_metalurgica_app/core/di/relogio_provider.dart';
import 'package:fera_metalurgica_app/core/router/app_router.dart';
import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_theme.dart';
import 'package:fera_metalurgica_app/core/utils/id_generator.dart';
import 'package:fera_metalurgica_app/features/cronograma/cronograma.dart';
import 'package:fera_metalurgica_app/features/empresa/empresa.dart';
import 'package:fera_metalurgica_app/features/materiais/materiais.dart';
import 'package:fera_metalurgica_app/features/orcamentos/orcamentos.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

/// Grava os dados de exemplo no banco recém-criado ([bancoNovo]) quando
/// [incluirExemplos] (o app passa `kDebugMode`, D-17): a empresa, um
/// material de cada unidade, os orçamentos C (A + B) e B, e tarefas de
/// hoje e de amanhã (HO-T8-01). Em release, o app começa vazio.
///
/// As datas saem do `agoraProvider`. Os orçamentos são gravados pelo
/// `FinalizarOrcamentoService` em dias anteriores (anteontem e ontem), para
/// que o primeiro orçamento do dia seja o `-01`.
///
/// Como só entram no banco novo, apagar tudo pelo app não traz os exemplos
/// de volta.
Future<void> popularDadosIniciais(
  ProviderContainer container, {
  required bool bancoNovo,
  required bool incluirExemplos,
}) async {
  if (!bancoNovo || !incluirExemplos) return;

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
      builder: (context, child) => _BarraDoSistema(child: child!),
    );
  }
}

/// Mantém o app acima da barra de navegação do sistema (voltar, início e
/// apps abertos) e pinta a área dela com o fundo do app. O Android recente
/// desenha o app por baixo da barra e ignora a cor pedida a ela, por isso o
/// espaço é reservado aqui, para todas as telas.
class _BarraDoSistema extends StatelessWidget {
  const _BarraDoSistema({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final escuro = Theme.of(context).brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        systemNavigationBarColor: colors.background,
        systemNavigationBarIconBrightness: escuro
            ? Brightness.light
            : Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      ),
      child: ColoredBox(
        color: colors.background,
        child: SafeArea(top: false, left: false, right: false, child: child),
      ),
    );
  }
}
