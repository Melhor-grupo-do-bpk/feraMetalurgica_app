import 'package:fera_metalurgica_app/core/di/relogio_provider.dart';
import 'package:fera_metalurgica_app/core/domain/dinheiro.dart';
import 'package:fera_metalurgica_app/features/cronograma/cronograma.dart';
import 'package:fera_metalurgica_app/features/orcamentos/orcamentos.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dashboard_indicadores.g.dart';

/// Valores dos 4 cards do dashboard (D-32).
typedef IndicadoresDashboard = ({
  int criados,
  int enviadosNoMes,
  Dinheiro valorEnviadoNoMes,
  int pedidosEmProducao,
});

/// Calcula os indicadores do dashboard conforme a D-32, no mês de [agora]:
/// - criados: orçamentos com status `criado`;
/// - enviados no mês e o valor deles: orçamentos `enviado` com `enviadoEm`
///   no mês (D-37), somando o total geral gravado;
/// - pedidos em produção: tarefas de produção pendentes.
IndicadoresDashboard calcularIndicadores(
  List<Orcamento> orcamentos,
  List<Tarefa> tarefas,
  DateTime agora,
) {
  bool noMes(DateTime? data) =>
      data != null && data.year == agora.year && data.month == agora.month;

  final enviados = [
    for (final o in orcamentos)
      if (o.status == StatusOrcamento.enviado && noMes(o.enviadoEm)) o,
  ];
  return (
    criados: orcamentos.where((o) => o.status == StatusOrcamento.criado).length,
    enviadosNoMes: enviados.length,
    valorEnviadoNoMes: enviados.fold(
      Dinheiro.zero,
      (soma, o) => soma + o.totalGeral,
    ),
    pedidosEmProducao: tarefas
        .where((t) => t.tipo == TipoTarefa.producao && !t.concluida)
        .length,
  );
}

/// Valor e quantidade de orçamentos enviados em um mês.
typedef EnvioDoMes = ({DateTime mes, Dinheiro valor, int quantidade});

/// Os [meses] últimos meses até o de [agora], do mais antigo ao atual, com
/// o valor e a quantidade dos orçamentos `enviado` cujo `enviadoEm` cai em
/// cada mês (D-37, D-45). Mês sem envio vem com zero.
List<EnvioDoMes> calcularEnviosPorMes(
  List<Orcamento> orcamentos,
  DateTime agora, {
  int meses = 6,
}) => [
  for (var i = meses - 1; i >= 0; i--)
    _envioDoMes(orcamentos, DateTime(agora.year, agora.month - i)),
];

EnvioDoMes _envioDoMes(List<Orcamento> orcamentos, DateTime mes) {
  final enviados = [
    for (final o in orcamentos)
      if (o.status == StatusOrcamento.enviado &&
          o.enviadoEm?.year == mes.year &&
          o.enviadoEm?.month == mes.month)
        o,
  ];
  return (
    mes: mes,
    valor: enviados.fold(Dinheiro.zero, (soma, o) => soma + o.totalGeral),
    quantidade: enviados.length,
  );
}

/// Os [limite] primeiros de [orcamentos] (que já vêm do `atualizadoEm` mais
/// recente para o mais antigo), D-32.
List<Orcamento> selecionarRecentes(
  List<Orcamento> orcamentos, {
  int limite = 2,
}) => orcamentos.take(limite).toList();

/// Contagem exibida no card, com pelo menos 2 dígitos (ex: `8` → `08`).
String formatarContagem(int valor) => valor.toString().padLeft(2, '0');

/// Indicadores do dashboard, recalculados sempre que orçamentos ou tarefas
/// mudam (RF-14).
///
/// Síncrono de propósito, como os filtros da lista: gravar algo não volta
/// a tela para o estado de carregamento.
@riverpod
AsyncValue<IndicadoresDashboard> indicadoresDashboard(Ref ref) {
  final orcamentos = ref.watch(orcamentosProvider);
  final tarefas = ref.watch(tarefasProvider);
  final agora = ref.watch(agoraProvider);
  return switch ((orcamentos, tarefas)) {
    (AsyncError(:final error, :final stackTrace), _) ||
    (
      _,
      AsyncError(:final error, :final stackTrace),
    ) => AsyncError(error, stackTrace),
    (AsyncData(value: final o), AsyncData(value: final t)) => AsyncData(
      calcularIndicadores(o, t, agora),
    ),
    _ => const AsyncLoading(),
  };
}

/// Enviados nos últimos 6 meses, para o gráfico do Início (D-45).
@riverpod
AsyncValue<List<EnvioDoMes>> enviosPorMes(Ref ref) {
  final agora = ref.watch(agoraProvider);
  return ref
      .watch(orcamentosProvider)
      .whenData((orcamentos) => calcularEnviosPorMes(orcamentos, agora));
}

/// Os 2 orçamentos de `atualizadoEm` mais recente (D-32).
@riverpod
AsyncValue<List<Orcamento>> recentesDashboard(Ref ref) =>
    ref.watch(orcamentosProvider).whenData(selecionarRecentes);
