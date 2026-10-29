import 'package:fera_metalurgica_app/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('somenteDigitos remove máscara', () {
    expect(somenteDigitos('(11) 98888-7777'), '11988887777');
    expect(somenteDigitos('abc'), '');
  });

  group('cpfValido', () {
    test('aceita CPF válido com ou sem máscara', () {
      expect(cpfValido('529.982.247-25'), isTrue);
      expect(cpfValido('52998224725'), isTrue);
    });

    test('rejeita dígito verificador errado, tamanho errado e repetidos', () {
      expect(cpfValido('529.982.247-24'), isFalse);
      expect(cpfValido('123.456.789-00'), isFalse);
      expect(cpfValido('5299822472'), isFalse);
      expect(cpfValido('111.111.111-11'), isFalse);
    });
  });

  group('cnpjValido', () {
    test('aceita CNPJ válido com ou sem máscara', () {
      expect(cnpjValido('11.222.333/0001-81'), isTrue);
      expect(cnpjValido('11444777000161'), isTrue);
    });

    test('rejeita dígito verificador errado, tamanho errado e repetidos', () {
      expect(cnpjValido('11.222.333/0001-80'), isFalse);
      expect(cnpjValido('1122233300018'), isFalse);
      expect(cnpjValido('00.000.000/0000-00'), isFalse);
    });
  });

  test('validarObrigatorio rejeita vazio e só espaços', () {
    expect(validarObrigatorio(null), 'Campo obrigatório');
    expect(validarObrigatorio('   '), 'Campo obrigatório');
    expect(validarObrigatorio('João'), isNull);
  });

  test('validarCpfCnpj escolhe a regra pelo número de dígitos', () {
    expect(validarCpfCnpj(''), 'Campo obrigatório');
    expect(validarCpfCnpj('529.982.247-25'), isNull);
    expect(validarCpfCnpj('529.982.247-24'), 'CPF inválido');
    expect(validarCpfCnpj('11.222.333/0001-81'), isNull);
    expect(validarCpfCnpj('11.222.333/0001-80'), 'CNPJ inválido');
    expect(validarCpfCnpj('123'), contains('11 dígitos'));
  });

  test('validarTelefone exige DDD + 8 ou 9 dígitos', () {
    expect(validarTelefone(null), 'Campo obrigatório');
    expect(validarTelefone('(11) 9888-7777'), isNull);
    expect(validarTelefone('(11) 98888-7777'), isNull);
    expect(validarTelefone('98888-7777'), 'Telefone inválido');
  });

  test('validarEmail é opcional, mas valida o formato se preenchido', () {
    expect(validarEmail(null), isNull);
    expect(validarEmail(''), isNull);
    expect(validarEmail('contato@apex.com.br'), isNull);
    expect(validarEmail('contato@apex'), 'E-mail inválido');
    expect(validarEmail('contato apex@x.com'), 'E-mail inválido');
  });
}
