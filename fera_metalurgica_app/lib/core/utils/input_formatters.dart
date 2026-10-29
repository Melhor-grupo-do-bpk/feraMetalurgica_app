import 'package:fera_metalurgica_app/core/utils/validators.dart';
import 'package:flutter/services.dart';

/// Aplica [mascara] a [digitos], trocando cada `#` por um dígito. Separadores
/// só aparecem quando há dígito depois deles (ex: `"123"` → `"123"`, e não
/// `"123."`).
String _aplicarMascara(String digitos, String mascara) {
  final buffer = StringBuffer();
  var i = 0;
  for (final caractere in mascara.split('')) {
    if (i >= digitos.length) break;
    if (caractere == '#') {
      buffer.write(digitos[i]);
      i++;
    } else {
      buffer.write(caractere);
    }
  }
  return buffer.toString();
}

/// Telefone com DDD: `(99) 9999-9999` com até 10 dígitos e
/// `(99) 99999-9999` com 11.
String formatarTelefone(String valor) {
  final digitos = somenteDigitos(valor);
  final limitado = digitos.length > 11 ? digitos.substring(0, 11) : digitos;
  return _aplicarMascara(
    limitado,
    limitado.length == 11 ? '(##) #####-####' : '(##) ####-####',
  );
}

/// CPF (`999.999.999-99`) com até 11 dígitos; CNPJ
/// (`99.999.999/9999-99`) com 12 a 14.
String formatarCpfCnpj(String valor) {
  final digitos = somenteDigitos(valor);
  final limitado = digitos.length > 14 ? digitos.substring(0, 14) : digitos;
  return _aplicarMascara(
    limitado,
    limitado.length <= 11 ? '###.###.###-##' : '##.###.###/####-##',
  );
}

/// Base dos formatters de máscara: reformata o texto inteiro e põe o
/// cursor no fim.
abstract class _MascaraInputFormatter extends TextInputFormatter {
  const _MascaraInputFormatter();

  String formatar(String valor);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final texto = formatar(newValue.text);
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}

/// Máscara de telefone para `TextField` (ver [formatarTelefone]).
class TelefoneInputFormatter extends _MascaraInputFormatter {
  /// Cria o formatter.
  const TelefoneInputFormatter();

  @override
  String formatar(String valor) => formatarTelefone(valor);
}

/// Máscara de CPF/CNPJ para `TextField`, que alterna conforme o número de
/// dígitos (ver [formatarCpfCnpj]).
class CpfCnpjInputFormatter extends _MascaraInputFormatter {
  /// Cria o formatter.
  const CpfCnpjInputFormatter();

  @override
  String formatar(String valor) => formatarCpfCnpj(valor);
}
