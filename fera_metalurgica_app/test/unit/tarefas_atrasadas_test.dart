import 'package:fera_metalurgica_app/features/cronograma/cronograma.dart';
import 'package:fera_metalurgica_app/features/cronograma/presentation/tarefas_atrasadas.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regra das tarefas atrasadas (v2-plano §6, item 7). Fica na pasta da
/// trilha V2-E: `test/unit/` é do orquestrador.
void main() {
  final agora = DateTime(2023, 10, 9, 8);

  Tarefa tarefa(DateTime data, {bool concluida = false}) => Tarefa(
    id: data.toIso8601String(),
    titulo: 'Tarefa',
    data: data,
    tipo: TipoTarefa.visita,
    concluida: concluida,
  );

  group('estaAtrasada', () {
    test('pendente de um dia anterior está atrasada', () {
      expect(estaAtrasada(tarefa(DateTime(2023, 10, 8, 23, 59)), agora), true);
      expect(estaAtrasada(tarefa(DateTime(2022, 12, 31)), agora), true);
    });

    test('hoje não está atrasada, nem com a hora já passada', () {
      expect(estaAtrasada(tarefa(DateTime(2023, 10, 9)), agora), false);
      expect(estaAtrasada(tarefa(DateTime(2023, 10, 9, 7)), agora), false);
      expect(
        estaAtrasada(tarefa(DateTime(2023, 10, 9)), DateTime(2023, 10, 9, 23)),
        false,
      );
    });

    test('futura não está atrasada', () {
      expect(estaAtrasada(tarefa(DateTime(2023, 10, 10)), agora), false);
    });

    test('concluída nunca está atrasada', () {
      expect(
        estaAtrasada(tarefa(DateTime(2023, 10, 3), concluida: true), agora),
        false,
      );
    });
  });

  test('tarefasAtrasadas filtra e ordena da mais antiga', () {
    final antiga = tarefa(DateTime(2023, 10, 3));
    final ontem = tarefa(DateTime(2023, 10, 8));
    final lista = [
      ontem,
      tarefa(DateTime(2023, 10, 9)),
      tarefa(DateTime(2023, 10, 4), concluida: true),
      antiga,
    ];

    expect(tarefasAtrasadas(lista, agora), [antiga, ontem]);
  });

  test('contarAtrasadas', () {
    expect(contarAtrasadas(1), '1 tarefa atrasada');
    expect(contarAtrasadas(2), '2 tarefas atrasadas');
  });
}
