/// Contador persistido da sequência diária dos códigos de orçamento (D-30).
/// Independente dos orçamentos existentes: excluir um orçamento não libera
/// o número.
abstract class SequenciaRepository {
  /// Reserva e devolve a próxima sequência do dia de [data] (só a data
  /// conta, não a hora), começando em 1. Deve rodar dentro da transação da
  /// gravação (`UnidadeDeTrabalho`).
  Future<int> proximaDoDia(DateTime data);
}
