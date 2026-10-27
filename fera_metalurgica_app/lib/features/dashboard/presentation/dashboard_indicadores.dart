import 'package:fera_metalurgica_app/features/cronograma/cronograma.dart';
import 'package:fera_metalurgica_app/features/orcamentos/orcamentos.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dashboard_indicadores.g.dart';

/// Contagens dos 4 cards do dashboard (D-03).
typedef IndicadoresDashboard = ({
  int emAndamento,
  int aguardandoAprovacao,
  int aprovados,
  int pedidosEmProducao,
});

/// Conta os indicadores do dashboard conforme D-03. `rascunho` e
/// `recusado` não entram em nenhum card; tarefas de produção concluídas
/// também não.
IndicadoresDashboard calcularIndicadores(
  List<Orcamento> orcamentos,
  List<Tarefa> tarefas,
) {
  int contar(StatusOrcamento status) =>
      orcamentos.where((o) => o.status == status).length;

  return (
    emAndamento: contar(StatusOrcamento.emAnalise),
    aguardandoAprovacao: contar(StatusOrcamento.enviado),
    aprovados: contar(StatusOrcamento.aprovado),
    pedidosEmProducao: tarefas
        .where((t) => t.tipo == TipoTarefa.producao && !t.concluida)
        .length,
  );
}

/// Os [limite] primeiros orçamentos de [orcamentos] que não são rascunho,
/// mantendo a ordem recebida (RF-12). Recusados entram.
List<Orcamento> selecionarRecentes(
  List<Orcamento> orcamentos, {
  int limite = 2,
}) => orcamentos
    .where((o) => o.status != StatusOrcamento.rascunho)
    .take(limite)
    .toList();

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
  return switch ((orcamentos, tarefas)) {
    (AsyncError(:final error, :final stackTrace), _) ||
    (
      _,
      AsyncError(:final error, :final stackTrace),
    ) => AsyncError(error, stackTrace),
    (AsyncData(value: final o), AsyncData(value: final t)) => AsyncData(
      calcularIndicadores(o, t),
    ),
    _ => const AsyncLoading(),
  };
}

/// Os 2 orçamentos mais recentes que não são rascunho (RF-12).
@riverpod
AsyncValue<List<Orcamento>> recentesDashboard(Ref ref) =>
    ref.watch(orcamentosProvider).whenData(selecionarRecentes);
