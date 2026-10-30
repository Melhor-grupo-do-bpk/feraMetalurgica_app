import 'package:fera_metalurgica_app/features/orcamentos/domain/codigo_orcamento.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatarCodigoOrcamento (DDMMAA-NN)', () {
    test('dia, mês e ano com dois dígitos e sequência com dois', () {
      expect(formatarCodigoOrcamento(DateTime(2026, 10, 28), 3), '281026-03');
      expect(
        formatarCodigoOrcamento(DateTime(2027, 1, 5, 23, 59), 1),
        '050127-01',
      );
      expect(formatarCodigoOrcamento(DateTime(2026, 10, 28), 42), '281026-42');
    });

    test('sequência acima de 99 cresce sem cortar', () {
      expect(
        formatarCodigoOrcamento(DateTime(2026, 10, 28), 100),
        '281026-100',
      );
      expect(
        formatarCodigoOrcamento(DateTime(2026, 10, 28), 1234),
        '281026-1234',
      );
    });

    test('sequência menor que 1 é rejeitada', () {
      expect(
        () => formatarCodigoOrcamento(DateTime(2026, 10, 28), 0),
        throwsArgumentError,
      );
    });
  });

  group('lerCodigoOrcamento', () {
    test('lê data e sequência de volta', () {
      final lido = lerCodigoOrcamento('281026-03')!;
      expect(lido.data, DateTime(2026, 10, 28));
      expect(lido.sequencia, 3);
      expect(lerCodigoOrcamento('281026-100')!.sequencia, 100);
    });

    test('ida e volta', () {
      final data = DateTime(2026, 2, 28);
      final lido = lerCodigoOrcamento(formatarCodigoOrcamento(data, 7))!;
      expect(lido, (data: data, sequencia: 7));
    });

    test('rejeita formato, data e sequência inválidos', () {
      for (final invalido in [
        '',
        '281026',
        '281026-3',
        '281026-003',
        '281026-00',
        '321026-01',
        '290226-01',
        '281326-01',
        '28102603',
        '281026-0a',
        ' 281026-03',
      ]) {
        expect(lerCodigoOrcamento(invalido), isNull, reason: invalido);
      }
    });
  });
}
