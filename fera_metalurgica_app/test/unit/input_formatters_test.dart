import 'package:fera_metalurgica_app/core/utils/input_formatters.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('MaiusculasInputFormatter deixa o texto em maiúsculas', () {
    final valor = const MaiusculasInputFormatter().formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(text: 'rs'),
    );
    expect(valor.text, 'RS');
  });

  group('formatarCep', () {
    test('põe o hífen depois do 5º dígito', () {
      expect(formatarCep(''), '');
      expect(formatarCep('01001'), '01001');
      expect(formatarCep('010010'), '01001-0');
      expect(formatarCep('01001000'), '01001-000');
    });

    test('ignora não dígitos e corta em 8', () {
      expect(formatarCep('01.001-000x9'), '01001-000');
    });
  });

  group('DinheiroInputFormatter', () {
    String digitar(String antes, String depois) =>
        const DinheiroInputFormatter()
            .formatEditUpdate(
              TextEditingValue(text: antes),
              TextEditingValue(text: depois),
            )
            .text;

    test('os dígitos entram pela direita, como centavos', () {
      expect(digitar('', '1'), '0,01');
      expect(digitar('0,01', '0,012'), '0,12');
      expect(digitar('0,12', '0,123'), '1,23');
      expect(digitar('1,23', '1,234'), '12,34');
      expect(digitar('123,45', '123,456'), '1.234,56');
    });

    test('apagar tira o último dígito', () {
      expect(digitar('1.234,56', '1.234,5'), '123,45');
    });

    test('zero vira 0,00, e apagar a partir daí limpa o campo', () {
      expect(digitar('', '0'), '0,00');
      expect(digitar('0,00', '0,0'), '');
      expect(digitar('0,01', ''), '');
    });

    test('ignora o que não é dígito', () {
      expect(digitar('', r'R$ 1.234,56'), '1.234,56');
      expect(digitar('', 'abc'), '');
    });

    test('recusa valores acima do limite', () {
      expect(
        digitar('99.999.999.999,99', '99.999.999.999,991'),
        '99.999.999.999,99',
      );
    });

    test('o cursor fica no fim', () {
      final valor = const DinheiroInputFormatter().formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '123'),
      );
      expect(valor.selection.baseOffset, valor.text.length);
    });
  });

  group('formatarTelefone', () {
    test('formata enquanto digita, sem separador sobrando', () {
      expect(formatarTelefone(''), '');
      expect(formatarTelefone('1'), '(1');
      expect(formatarTelefone('11'), '(11');
      expect(formatarTelefone('119'), '(11) 9');
      expect(formatarTelefone('1198887'), '(11) 9888-7');
    });

    test('usa 4 dígitos antes do hífen com 10 e 5 com 11', () {
      expect(formatarTelefone('1198887777'), '(11) 9888-7777');
      expect(formatarTelefone('11988887777'), '(11) 98888-7777');
    });

    test('ignora não dígitos e corta em 11 dígitos', () {
      expect(formatarTelefone('(11) 98888-77779'), '(11) 98888-7777');
    });
  });

  group('formatarCpfCnpj', () {
    test('usa máscara de CPF até 11 dígitos', () {
      expect(formatarCpfCnpj('529'), '529');
      expect(formatarCpfCnpj('5299'), '529.9');
      expect(formatarCpfCnpj('52998224725'), '529.982.247-25');
    });

    test('troca para CNPJ a partir de 12 dígitos e corta em 14', () {
      expect(formatarCpfCnpj('112223330001'), '11.222.333/0001');
      expect(formatarCpfCnpj('11222333000181'), '11.222.333/0001-81');
      expect(formatarCpfCnpj('112223330001819'), '11.222.333/0001-81');
    });
  });

  test('formatters aplicam a máscara e põem o cursor no fim', () {
    TextEditingValue formatar(TextInputFormatter formatter, String texto) =>
        formatter.formatEditUpdate(
          TextEditingValue.empty,
          TextEditingValue(text: texto),
        );

    final telefone = formatar(const TelefoneInputFormatter(), '11988887777');
    expect(telefone.text, '(11) 98888-7777');
    expect(telefone.selection.baseOffset, telefone.text.length);

    final documento = formatar(const CpfCnpjInputFormatter(), '52998224725');
    expect(documento.text, '529.982.247-25');
    expect(documento.selection.baseOffset, documento.text.length);
  });
}
