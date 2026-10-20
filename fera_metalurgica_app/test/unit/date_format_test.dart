import 'package:fera_metalurgica_app/core/utils/date_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formatarData usa dd/MM/yyyy', () {
    expect(formatarData(DateTime(2026, 8, 7)), '07/08/2026');
  });

  test('formatarHora usa HH:mm com dois dígitos', () {
    expect(formatarHora(DateTime(2023, 10, 9, 9)), '09:00');
    expect(formatarHora(DateTime(2023, 10, 9, 14, 30)), '14:30');
  });

  test('formatarDiaCurto reproduz os atalhos do cronograma', () {
    expect(formatarDiaCurto(DateTime(2023, 10, 11)), 'Qua, 11 Out');
    expect(formatarDiaCurto(DateTime(2023, 10, 8)), 'Dom, 8 Out');
    expect(formatarDiaCurto(DateTime(2023, 10, 14)), 'Sáb, 14 Out');
  });

  test('formatarMesAno escreve o mês por extenso', () {
    expect(formatarMesAno(DateTime(2023, 10)), 'Outubro 2023');
    expect(formatarMesAno(DateTime(2026, 3)), 'Março 2026');
  });
}
