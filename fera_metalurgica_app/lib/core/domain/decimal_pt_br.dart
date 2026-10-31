// Leitura e escrita de números decimais em pt-BR, sem passar por `double`.
// Base de `Dinheiro` e `MedidaCm` (D-26).

final RegExp _somenteDigitos = RegExp(r'^\d+$');
final RegExp _milhar = RegExp(r'^\d{1,3}(\.\d{3})+$');

/// Maior parte inteira aceita: 13 dígitos, para que o valor em centésimos
/// caiba com folga num `int`.
const int _maxDigitosInteiros = 13;

/// Lê [texto] como um decimal pt-BR com até duas casas e devolve o valor em
/// centésimos (ex: `"1.234,5"` → `123450`).
///
/// Aceita:
/// - vírgula decimal, com ou sem ponto de milhar (`"1.234,56"`, `"1234,5"`);
/// - ponto decimal, quando não há vírgula e o único ponto tem 1 ou 2
///   dígitos depois dele (`"7.5"`, `"10.25"`), porque muitos teclados
///   numéricos de celular só têm ponto;
/// - ponto de milhar, com grupos de 3 dígitos (`"1.500"` → 1500).
///
/// Devolve `null` para texto vazio, sinal, mais de duas casas, agrupamento
/// inválido ou qualquer outro caractere. Vazio nunca vira zero.
int? lerCentesimosPtBr(String texto) {
  final valor = texto.trim();
  if (valor.isEmpty) return null;

  String inteiro;
  var decimal = '';

  final partes = valor.split(',');
  if (partes.length > 2) return null;
  if (partes.length == 2) {
    inteiro = partes[0];
    decimal = partes[1];
    if (decimal.isEmpty) return null;
  } else {
    final grupos = valor.split('.');
    if (grupos.length == 2 &&
        (grupos[1].length == 1 || grupos[1].length == 2)) {
      inteiro = grupos[0];
      decimal = grupos[1];
    } else {
      inteiro = valor;
    }
  }

  if (inteiro.contains('.')) {
    if (!_milhar.hasMatch(inteiro)) return null;
    inteiro = inteiro.replaceAll('.', '');
  }
  if (!_somenteDigitos.hasMatch(inteiro)) return null;
  if (inteiro.length > _maxDigitosInteiros) return null;
  if (decimal.isNotEmpty && !_somenteDigitos.hasMatch(decimal)) return null;
  if (decimal.length > 2) return null;

  return int.parse(inteiro) * 100 + int.parse(decimal.padRight(2, '0'));
}

/// Inteiro com ponto de milhar pt-BR (ex: `1200` → `1.200`, `-1200` →
/// `-1.200`).
String comMilharPtBr(int valor) {
  final digitos = valor.abs().toString();
  final buffer = StringBuffer(valor < 0 ? '-' : '');
  for (var i = 0; i < digitos.length; i++) {
    if (i > 0 && (digitos.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digitos[i]);
  }
  return buffer.toString();
}

/// Escreve [centesimos] em pt-BR com duas casas e ponto de milhar (ex:
/// `123456` → `1.234,56`, `-5` → `-0,05`). Só aritmética de `int`: exato
/// para qualquer valor.
String formatarCentesimosPtBr(int centesimos) {
  final sinal = centesimos < 0 ? '-' : '';
  final inteiro = (centesimos ~/ 100).abs();
  final decimal = centesimos.remainder(100).abs().toString().padLeft(2, '0');
  return '$sinal${comMilharPtBr(inteiro)},$decimal';
}
