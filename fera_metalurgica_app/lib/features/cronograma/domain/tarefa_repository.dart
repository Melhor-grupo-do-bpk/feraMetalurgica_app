import 'package:fera_metalurgica_app/features/cronograma/domain/tarefa.dart';

/// Contrato de persistência das tarefas do cronograma.
///
/// Não crie uma segunda implementação/local de acesso a tarefas: toda
/// leitura/escrita de tarefas passa por aqui.
abstract class TarefaRepository {
  /// Retorna todas as tarefas salvas.
  Future<List<Tarefa>> getAll();

  /// Cria ou atualiza uma tarefa.
  Future<void> save(Tarefa tarefa);

  /// Remove a tarefa de identificador [id].
  Future<void> delete(String id);
}
