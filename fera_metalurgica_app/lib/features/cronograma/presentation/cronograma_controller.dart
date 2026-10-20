import 'package:fera_metalurgica_app/features/cronograma/data/cronograma_repository_impl.dart';
import 'package:fera_metalurgica_app/features/cronograma/domain/tarefa.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cronograma_controller.g.dart';

/// Tarefas do cronograma, em ordem cronológica.
///
/// Estado compartilhado da feature (lido também pelo dashboard). Trilhas
/// podem adicionar métodos, mas não renomear/remover os existentes
/// (`docs/03-padroes.md` §2).
@Riverpod(keepAlive: true)
class Tarefas extends _$Tarefas {
  @override
  Future<List<Tarefa>> build() async =>
      _ordenar(await ref.watch(cronogramaRepositoryProvider).getAll());

  /// Cria ou atualiza [tarefa].
  Future<void> salvar(Tarefa tarefa) async {
    final repository = ref.read(cronogramaRepositoryProvider);
    await repository.save(tarefa);
    state = AsyncData(_ordenar(await repository.getAll()));
  }

  /// Remove a tarefa de identificador [id].
  Future<void> excluir(String id) async {
    final repository = ref.read(cronogramaRepositoryProvider);
    await repository.delete(id);
    state = AsyncData(_ordenar(await repository.getAll()));
  }

  /// Inverte `concluida` da tarefa [id]; não faz nada se ela não existir.
  Future<void> alternarConcluida(String id) async {
    final tarefas = await future;
    final tarefa = tarefas.where((t) => t.id == id).firstOrNull;
    if (tarefa == null) return;
    await salvar(tarefa.copyWith(concluida: !tarefa.concluida));
  }

  static List<Tarefa> _ordenar(List<Tarefa> tarefas) =>
      [...tarefas]..sort((a, b) => a.data.compareTo(b.data));
}

/// Tarefa de identificador [id], ou `null` se não existir.
@riverpod
Future<Tarefa?> tarefaPorId(Ref ref, String id) async {
  final tarefas = await ref.watch(tarefasProvider.future);
  return tarefas.where((t) => t.id == id).firstOrNull;
}
