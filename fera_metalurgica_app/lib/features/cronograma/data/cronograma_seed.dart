import 'package:fera_metalurgica_app/features/cronograma/domain/tarefa.dart';
import 'package:fera_metalurgica_app/features/cronograma/domain/tipo_tarefa.dart';

/// Tarefas de exemplo (D-17), com os títulos e horários da tela "Cronograma
/// e Agenda" do Figma, nas datas de hoje e de amanhã a partir de [agora]
/// (HO-T8-01): assim a agenda não abre vazia.
///
/// Com [orcamentoId], a revisão fica vinculada a esse orçamento, e o título
/// mostra o [codigoOrcamento].
List<Tarefa> cronogramaSeed(
  DateTime agora, {
  String? orcamentoId,
  String? codigoOrcamento,
}) {
  DateTime dia(int deslocamento, int hora, [int minuto = 0]) =>
      DateTime(agora.year, agora.month, agora.day + deslocamento, hora, minuto);
  return [
    Tarefa(
      id: 'tarefa-revisar-orcamento',
      titulo: codigoOrcamento == null
          ? 'Revisar orçamento'
          : 'Revisar orçamento $codigoOrcamento',
      data: dia(0, 9),
      tipo: TipoTarefa.orcamento,
      descricao: 'Cliente: João da Silva',
      orcamentoId: orcamentoId,
    ),
    Tarefa(
      id: 'tarefa-manutencao-torno',
      titulo: 'Manutenção preventiva Torno CNC',
      data: dia(0, 11, 30),
      tipo: TipoTarefa.producao,
      concluida: true,
    ),
    Tarefa(
      id: 'tarefa-producao-00124',
      titulo: 'Iniciar produção do pedido #00124',
      data: dia(1, 14),
      tipo: TipoTarefa.producao,
      descricao: 'Linha de montagem B - Peças usinadas pesadas.',
    ),
  ];
}
