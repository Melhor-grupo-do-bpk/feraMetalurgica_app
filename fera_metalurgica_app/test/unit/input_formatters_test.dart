import 'package:fera_metalurgica_app/core/utils/input_formatters.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
