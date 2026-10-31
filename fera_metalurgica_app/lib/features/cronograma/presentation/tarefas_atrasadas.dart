import 'package:fera_metalurgica_app/core/di/relogio_provider.dart';
import 'package:fera_metalurgica_app/features/cronograma/domain/tarefa.dart';
import 'package:fera_metalurgica_app/features/cronograma/presentation/cronograma/calendario_mes.dart';
import 'package:fera_metalurgica_app/features/cronograma/presentation/cronograma_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tarefas_atrasadas.g.dart';

/// A [tarefa] está atrasada (v2-plano §6, item 7): pendente e de um dia
/// anterior ao de [agora]. Uma tarefa de hoje, mesmo com a hora já
/// passada, não está atrasada.
bool estaAtrasada(Tarefa tarefa, DateTime agora) =>
    !tarefa.concluida && soDia(tarefa.data).isBefore(soDia(agora));

/// As tarefas atrasadas de [tarefas], em ordem cronológica.
List<Tarefa> tarefasAtrasadas(List<Tarefa> tarefas, DateTime agora) => [
  for (final t in tarefas)
    if (estaAtrasada(t, agora)) t,
]..sort((a, b) => a.data.compareTo(b.data));

/// Tarefas atrasadas em relação ao [agoraProvider], de todos os tipos (o
/// aviso da agenda não depende dos filtros).
@riverpod
AsyncValue<List<Tarefa>> atrasadas(Ref ref) {
  final agora = ref.watch(agoraProvider);
  return ref
      .watch(tarefasProvider)
      .whenData((tarefas) => tarefasAtrasadas(tarefas, agora));
}

/// "1 tarefa atrasada", "3 tarefas atrasadas".
String contarAtrasadas(int quantidade) =>
    quantidade == 1 ? '1 tarefa atrasada' : '$quantidade tarefas atrasadas';
