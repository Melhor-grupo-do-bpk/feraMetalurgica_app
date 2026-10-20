import 'package:fera_metalurgica_app/features/cronograma/cronograma.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('descricao e orcamentoId fazem ida e volta no JSON', () {
    final tarefa = cronogramaSeed.firstWhere((t) => t.orcamentoId != null);

    expect(Tarefa.fromJson(tarefa.toJson()), tarefa);
    expect(tarefa.toJson()['descricao'], 'Cliente: João da Silva');
    expect(tarefa.toJson()['orcamentoId'], '00482');
  });

  test('JSON salvo antes da F1 (sem os campos novos) continua legível', () {
    final tarefa = Tarefa.fromJson({
      'id': 't1',
      'titulo': 'Visita técnica',
      'data': '2023-10-09T09:00:00.000',
      'tipo': 'visita',
    });

    expect(tarefa.descricao, isNull);
    expect(tarefa.orcamentoId, isNull);
    expect(tarefa.concluida, isFalse);
  });
}
