import 'package:fera_metalurgica_app/features/cronograma/presentation/cronograma/calendario_mes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('diasDaGrade', () {
    test('outubro de 2023: dia 1 no domingo, 5 semanas', () {
      final dias = diasDaGrade(DateTime(2023, 10, 9));

      expect(dias.length, 5 * 7);
      expect(dias.first, DateTime(2023, 10));
      expect(dias.indexOf(DateTime(2023, 10)), 0);
      expect(dias.last, DateTime(2023, 11, 4));
    });

    test('fevereiro de 2026: 28 dias a partir do domingo, 4 semanas', () {
      final dias = diasDaGrade(DateTime(2026, 2));

      expect(dias.length, 4 * 7);
      expect(dias.first, DateTime(2026, 2));
      expect(dias.last, DateTime(2026, 2, 28));
    });

    test('março de 2025: dia 1 no sábado, 6 semanas', () {
      final dias = diasDaGrade(DateTime(2025, 3));

      expect(dias.length, 6 * 7);
      expect(dias.indexOf(DateTime(2025, 3)), 6);
      expect(dias.first, DateTime(2025, 2, 23));
      expect(dias.last, DateTime(2025, 4, 5));
    });

    test('a primeira coluna é sempre domingo e os dias são seguidos', () {
      for (var mes = 1; mes <= 12; mes++) {
        final dias = diasDaGrade(DateTime(2024, mes));

        expect(dias.length % 7, 0);
        for (var i = 0; i < dias.length; i += 7) {
          expect(dias[i].weekday, DateTime.sunday);
        }
        for (var i = 1; i < dias.length; i++) {
          expect(
            dias[i].difference(dias[i - 1]).inHours,
            inInclusiveRange(23, 25),
          );
          expect(dias[i].hour, 0);
        }
      }
    });
  });

  test('mesmoDia ignora a hora e soDia zera a hora', () {
    expect(
      mesmoDia(DateTime(2023, 10, 9, 8), DateTime(2023, 10, 9, 23)),
      isTrue,
    );
    expect(mesmoDia(DateTime(2023, 10, 9), DateTime(2023, 10, 10)), isFalse);
    expect(soDia(DateTime(2023, 10, 9, 11, 30)), DateTime(2023, 10, 9));
  });
}
