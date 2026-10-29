import 'package:fera_metalurgica_app/core/domain/medida_cm.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MedidaCm.tryParse', () {
    test('lê pt-BR com até duas casas', () {
      expect(MedidaCm.tryParse('75'), const MedidaCm(7500));
      expect(MedidaCm.tryParse('7,5'), const MedidaCm(750));
      expect(MedidaCm.tryParse('0,25'), const MedidaCm(25));
      expect(MedidaCm.tryParse('1.200,5'), const MedidaCm(120050));
    });

    test('ponto com 1 ou 2 dígitos depois, sem vírgula, é decimal', () {
      expect(MedidaCm.tryParse('7.5'), const MedidaCm(750));
      expect(MedidaCm.tryParse('10.25'), const MedidaCm(1025));
    });

    test('ponto com 3 dígitos depois é milhar', () {
      expect(MedidaCm.tryParse('1.500'), const MedidaCm(150000));
    });

    test('vazio é nulo, nunca zero; zero digitado é zero', () {
      expect(MedidaCm.tryParse(''), isNull);
      expect(MedidaCm.tryParse('  '), isNull);
      expect(MedidaCm.tryParse('0'), const MedidaCm(0));
      expect(MedidaCm.tryParse('0')!.ehPositiva, isFalse);
    });

    test('rejeita mais de duas casas, sinal e texto', () {
      for (final invalido in ['7,555', '0,001', '-5', 'cm', '7,5cm', '1.2.3']) {
        expect(MedidaCm.tryParse(invalido), isNull, reason: invalido);
      }
      expect(() => MedidaCm.parse('7,555'), throwsFormatException);
    });
  });

  test('formata sem zeros à direita', () {
    expect(const MedidaCm(7500).formatada, '75');
    expect(const MedidaCm(750).formatada, '7,5');
    expect(const MedidaCm(25).formatada, '0,25');
    expect(const MedidaCm(120050).formatada, '1.200,5');
  });

  test('JSON é int de centésimos', () {
    const conversor = MedidaCmJsonConverter();
    expect(conversor.toJson(const MedidaCm(750)), 750);
    expect(conversor.fromJson(750), const MedidaCm(750));
  });
}
