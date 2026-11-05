import 'dart:convert';

import 'package:fera_metalurgica_app/core/domain/consumo.dart';
import 'package:fera_metalurgica_app/core/domain/unidade_cobranca.dart';
import 'package:flutter_test/flutter_test.dart';

Consumo _m3(String escala) =>
    Consumo(unidade: UnidadeCobranca.m3, valor: BigInt.parse(escala));

void main() {
  test('texto canônico tem ponto e 12 casas', () {
    expect(_m3('4800000000').textoCanonico, '0.004800000000');
    expect(_m3('1620000000000').textoCanonico, '1.620000000000');
    expect(Consumo.zero(UnidadeCobranca.m2).textoCanonico, '0.000000000000');
  });

  test('exibição pt-BR sem zeros à direita, até 12 casas', () {
    expect(_m3('4800000000').formatado, '0,0048');
    expect(_m3('1620000000000').formatado, '1,62');
    expect(_m3('3000000000000').formatado, '3');
    expect(_m3('1').formatado, '0,000000000001');
    expect(_m3('4800000000').formatadoComUnidade, '0,0048 m³');
  });

  test('soma consumos da mesma unidade e multiplica por inteiro', () {
    expect(_m3('4800000000') * 4, _m3('19200000000'));
    expect(_m3('4800000000') + _m3('200000000'), _m3('5000000000'));
  });

  test('não soma m² com m³', () {
    final m2 = Consumo(unidade: UnidadeCobranca.m2, valor: BigInt.from(1));
    expect(() => m2 + _m3('1'), throwsArgumentError);
  });

  test('JSON leva a unidade e o valor em texto canônico', () {
    final consumo = _m3('4800000000');
    final json = jsonDecode(jsonEncode(consumo)) as Map<String, dynamic>;
    expect(json, {'unidade': 'm3', 'valor': '0.004800000000'});
    expect(Consumo.fromJson(json), consumo);
  });

  test('JSON fora do texto canônico é rejeitado', () {
    expect(
      () => Consumo.fromJson({'unidade': 'm2', 'valor': '0.0048'}),
      throwsFormatException,
    );
  });
}
