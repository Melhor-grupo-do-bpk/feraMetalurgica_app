import 'dart:convert';

import 'package:fera_metalurgica_app/core/domain/dinheiro.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Dinheiro.tryParse', () {
    test(r'lê vírgula decimal, com ou sem milhar e R$', () {
      expect(Dinheiro.tryParse('1.234,56'), const Dinheiro(123456));
      expect(Dinheiro.tryParse('1234,5'), const Dinheiro(123450));
      expect(Dinheiro.tryParse(r'R$ 10'), const Dinheiro(1000));
      expect(Dinheiro.tryParse(r'R$1.500,00'), const Dinheiro(150000));
      expect(Dinheiro.tryParse(' 0,01 '), const Dinheiro(1));
      expect(Dinheiro.tryParse('0'), Dinheiro.zero);
      expect(Dinheiro.tryParse('1.234.567,89'), const Dinheiro(123456789));
    });

    test('ponto com 1 ou 2 dígitos depois, sem vírgula, é decimal', () {
      expect(Dinheiro.tryParse('7.5'), const Dinheiro(750));
      expect(Dinheiro.tryParse('10.25'), const Dinheiro(1025));
      expect(Dinheiro.tryParse('3500.00'), const Dinheiro(350000));
    });

    test('ponto com 3 dígitos depois, ou vários grupos, é milhar', () {
      expect(Dinheiro.tryParse('1.500'), const Dinheiro(150000));
      expect(Dinheiro.tryParse('1.234.567'), const Dinheiro(123456700));
      expect(Dinheiro.tryParse('1.234,56'), const Dinheiro(123456));
    });

    test('rejeita vazio, sinal, mais de duas casas e formatos inválidos', () {
      for (final invalido in [
        '',
        '   ',
        '-10',
        '+10',
        '1,234',
        '0,001',
        '1.2345',
        '1.234.5',
        '12.34.56',
        '1,2,3',
        '10,',
        ',5',
        '.5',
        '10.',
        'abc',
        '1 000',
        '1e3',
        '12345678901234',
      ]) {
        expect(Dinheiro.tryParse(invalido), isNull, reason: invalido);
      }
    });

    test('parse lança FormatException quando inválido', () {
      expect(() => Dinheiro.parse('1,234'), throwsFormatException);
      expect(Dinheiro.parse('90'), const Dinheiro(9000));
    });
  });

  group('Dinheiro (aritmética)', () {
    test('soma, subtrai, multiplica por inteiro e compara', () {
      const a = Dinheiro(55320);
      const b = Dinheiro(80000);
      expect(a + b, const Dinheiro(135320));
      expect(b - a, const Dinheiro(24680));
      expect(a - b, const Dinheiro(-24680));
      expect((a + b) * 2, const Dinheiro(270640));
      expect(a < b, isTrue);
      expect(b >= b, isTrue);
      expect([b, a]..sort(), [a, b]);
      expect(Dinheiro.zero.ehZero, isTrue);
      expect((a - b).ehNegativo, isTrue);
    });

    test('0,01 somado cem vezes é exatamente 1,00 (sem double)', () {
      var total = Dinheiro.zero;
      for (var i = 0; i < 100; i++) {
        total += const Dinheiro(1);
      }
      expect(total, const Dinheiro(100));
    });
  });

  test('formata em pt-BR com e sem símbolo', () {
    expect(const Dinheiro(270640).formatado, r'R$ 2.706,40');
    expect(const Dinheiro(1).formatado, r'R$ 0,01');
    expect(Dinheiro.zero.formatado, r'R$ 0,00');
    expect(const Dinheiro(123456789).formatadoSemSimbolo, '1.234.567,89');
    expect(const Dinheiro(845000).formatado, r'R$ 8.450,00');
    expect(const Dinheiro(1520050).formatado, r'R$ 15.200,50');
    expect(const Dinheiro(-363080).formatado, r'R$ -3.630,80');
    expect(const Dinheiro(-5).formatadoSemSimbolo, '-0,05');
  });

  test('formata valores grandes sem perder centavos (sem double)', () {
    // 2^53 + 1 centavos: um `double` arredondaria para ...992.
    const doisElevado53 = 9007199254740992;
    expect(
      const Dinheiro(doisElevado53 + 1).formatadoSemSimbolo,
      '90.071.992.547.409,93',
    );
    // Maior valor que `Dinheiro.tryParse` aceita (13 dígitos inteiros).
    expect(
      const Dinheiro(999999999999999).formatado,
      r'R$ 9.999.999.999.999,99',
    );
    expect(
      Dinheiro.tryParse(const Dinheiro(999999999999999).formatadoSemSimbolo),
      const Dinheiro(999999999999999),
    );
  });

  test('JSON é int de centavos', () {
    const conversor = DinheiroJsonConverter();
    expect(conversor.toJson(const Dinheiro(363080)), 363080);
    expect(
      conversor.fromJson(jsonDecode('363080') as int),
      const Dinheiro(363080),
    );
  });
}
