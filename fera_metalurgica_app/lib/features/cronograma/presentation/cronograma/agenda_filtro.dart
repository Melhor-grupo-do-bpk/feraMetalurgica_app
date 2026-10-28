import 'package:fera_metalurgica_app/core/di/relogio_provider.dart';
import 'package:fera_metalurgica_app/core/utils/date_format.dart';
import 'package:fera_metalurgica_app/features/cronograma/domain/tarefa.dart';
import 'package:fera_metalurgica_app/features/cronograma/domain/tipo_tarefa.dart';
import 'package:fera_metalurgica_app/features/cronograma/presentation/cronograma/calendario_mes.dart';
import 'package:fera_metalurgica_app/features/cronograma/presentation/cronograma_controller.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'agenda_filtro.freezed.dart';
part 'agenda_filtro.g.dart';

/// Estado da Tela 10: dia selecionado, mês exibido no calendário e tipos
/// marcados nos filtros (D-05). Estado de tela, não é persistido.
@freezed
abstract class AgendaFiltro with _$AgendaFiltro {
  /// Cria um [AgendaFiltro].
  const factory AgendaFiltro({
    /// Dia selecionado (sem hora); define a linha do tempo e os atalhos.
    required DateTime diaSelecionado,

    /// Primeiro dia do mês exibido no calendário.
    required DateTime mesExibido,

    /// Tipos marcados em "Filtros de tarefas".
    required Set<TipoTarefa> tipos,
  }) = _AgendaFiltro;
}

/// Uma seção da linha do tempo: um dia e as tarefas visíveis nele, em
/// ordem de hora.
typedef SecaoAgenda = ({DateTime dia, List<Tarefa> tarefas});

/// O que a Tela 10 mostra a partir das tarefas: as seções da linha do tempo
/// (dia selecionado e o seguinte) e os dias com ponto no calendário.
typedef Agenda = ({List<SecaoAgenda> secoes, Set<DateTime> diasComPendencia});

/// Filtros da Tela 10. Começa em "hoje" (de [agoraProvider]), no mês de
/// hoje, com os 3 tipos marcados.
@riverpod
class AgendaFiltroController extends _$AgendaFiltroController {
  @override
  AgendaFiltro build() {
    final hoje = soDia(ref.watch(agoraProvider));
    return AgendaFiltro(
      diaSelecionado: hoje,
      mesExibido: DateTime(hoje.year, hoje.month),
      tipos: TipoTarefa.values.toSet(),
    );
  }

  /// Seleciona [dia]; o calendário passa a exibir o mês dele.
  void selecionarDia(DateTime dia) => state = state.copyWith(
    diaSelecionado: soDia(dia),
    mesExibido: DateTime(dia.year, dia.month),
  );

  /// Avança (ou volta, com [meses] negativo) o mês exibido, sem mudar o
  /// dia selecionado.
  void mudarMes(int meses) => state = state.copyWith(
    mesExibido: DateTime(state.mesExibido.year, state.mesExibido.month + meses),
  );

  /// Marca ou desmarca o filtro do [tipo].
  void marcarTipo(TipoTarefa tipo, {required bool marcado}) =>
      state = state.copyWith(
        tipos: marcado
            ? {...state.tipos, tipo}
            : ({...state.tipos}..remove(tipo)),
      );
}

/// Seções e pontos do calendário, a partir de [tarefasProvider] e dos
/// filtros da tela.
@riverpod
AsyncValue<Agenda> agenda(Ref ref) {
  final filtro = ref.watch(agendaFiltroControllerProvider);
  return ref
      .watch(tarefasProvider)
      .whenData(
        (tarefas) => montarAgenda(
          tarefas,
          diaSelecionado: filtro.diaSelecionado,
          tipos: filtro.tipos,
        ),
      );
}

/// Monta a [Agenda]: seções do [diaSelecionado] e do dia seguinte, e os
/// dias com tarefa pendente; ambos só com as tarefas dos [tipos].
Agenda montarAgenda(
  List<Tarefa> tarefas, {
  required DateTime diaSelecionado,
  required Set<TipoTarefa> tipos,
}) {
  final visiveis = [
    for (final t in tarefas)
      if (tipos.contains(t.tipo)) t,
  ]..sort((a, b) => a.data.compareTo(b.data));

  SecaoAgenda secao(DateTime dia) => (
    dia: dia,
    tarefas: [
      for (final t in visiveis)
        if (mesmoDia(t.data, dia)) t,
    ],
  );

  final dia = soDia(diaSelecionado);
  return (
    secoes: [secao(dia), secao(DateTime(dia.year, dia.month, dia.day + 1))],
    diasComPendencia: {
      for (final t in visiveis)
        if (!t.concluida) soDia(t.data),
    },
  );
}

/// Nome do [dia] relativo a [hoje]: "Hoje", "Amanhã" ou "Qua, 11 Out".
String rotuloDia(DateTime dia, DateTime hoje) {
  final h = soDia(hoje);
  if (mesmoDia(dia, h)) return 'Hoje';
  if (mesmoDia(dia, DateTime(h.year, h.month, h.day + 1))) return 'Amanhã';
  return formatarDiaCurto(dia);
}

/// Texto do atalho do [dia]: "Hoje, 9 Out", "Amanhã, 10 Out" ou
/// "Qua, 11 Out".
String rotuloAtalho(DateTime dia, DateTime hoje) {
  final curto = formatarDiaCurto(dia);
  final rotulo = rotuloDia(dia, hoje);
  return rotulo == curto ? curto : '$rotulo, ${curto.split(', ').last}';
}

/// Contagem da seção: "1 tarefa", "2 tarefas", "0 tarefas".
String contarTarefas(int quantidade) =>
    quantidade == 1 ? '1 tarefa' : '$quantidade tarefas';
