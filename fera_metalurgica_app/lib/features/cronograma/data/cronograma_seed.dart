import 'package:fera_metalurgica_app/features/cronograma/domain/tarefa.dart';
import 'package:fera_metalurgica_app/features/cronograma/domain/tipo_tarefa.dart';

/// Tarefas de exemplo, com títulos, horários e datas da tela "Cronograma e
/// Agenda" do Figma (9 e 10 de outubro de 2023). A revisão aponta para o
/// orçamento #00482 dos dados de exemplo de orçamentos.
final List<Tarefa> cronogramaSeed = [
  Tarefa(
    id: 'tarefa-revisar-00482',
    titulo: 'Revisar orçamento #00482',
    data: DateTime(2023, 10, 9, 9),
    tipo: TipoTarefa.orcamento,
    descricao: 'Cliente: João da Silva',
    orcamentoId: '00482',
  ),
  Tarefa(
    id: 'tarefa-manutencao-torno',
    titulo: 'Manutenção preventiva Torno CNC',
    data: DateTime(2023, 10, 9, 11, 30),
    tipo: TipoTarefa.producao,
    concluida: true,
  ),
  Tarefa(
    id: 'tarefa-producao-00124',
    titulo: 'Iniciar produção do pedido #00124',
    data: DateTime(2023, 10, 10, 14),
    tipo: TipoTarefa.producao,
    descricao: 'Linha de montagem B - Peças usinadas pesadas.',
  ),
];
