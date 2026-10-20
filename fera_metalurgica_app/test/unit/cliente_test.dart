import 'package:fera_metalurgica_app/features/orcamentos/orcamentos.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Cliente cliente(String cpfCnpj) =>
      Cliente(id: 'c1', nome: 'X', numero: '11988887777', cpfCnpj: cpfCnpj);

  test('ehPessoaJuridica é verdadeiro com 14 dígitos (CNPJ)', () {
    expect(cliente('11.222.333/0001-81').ehPessoaJuridica, isTrue);
    expect(cliente('11222333000181').ehPessoaJuridica, isTrue);
  });

  test('ehPessoaJuridica é falso para CPF ou valor fora do padrão', () {
    expect(cliente('529.982.247-25').ehPessoaJuridica, isFalse);
    expect(cliente('').ehPessoaJuridica, isFalse);
  });
}
