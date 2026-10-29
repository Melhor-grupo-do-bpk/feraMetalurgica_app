import 'package:fera_metalurgica_app/core/domain/decimal_pt_br.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'medida_cm.freezed.dart';

/// Medida exata em centímetros, guardada em centésimos de cm (D-26): `7500`
/// é 75 cm e `25` é 0,25 cm. A entrada aceita até duas casas decimais.
///
/// No JSON é um `int` de centésimos (ver [MedidaCmJsonConverter]).
@freezed
abstract class MedidaCm with _$MedidaCm implements Comparable<MedidaCm> {
  /// Cria uma [MedidaCm] com [centesimos] de centímetro.
  const factory MedidaCm(int centesimos) = _MedidaCm;

  const MedidaCm._();

  /// Lê uma medida digitada em pt-BR, com até duas casas (ex: `"75"`,
  /// `"7,5"`, `"0,25"`, `"7.5"`), sem passar por `double`.
  ///
  /// Devolve `null` para texto vazio ou inválido: campo vazio nunca vira
  /// uma medida zero (prompt §6, "Entrada"). As regras de ponto e vírgula
  /// estão em [lerCentesimosPtBr].
  static MedidaCm? tryParse(String texto) {
    final centesimos = lerCentesimosPtBr(texto);
    return centesimos == null ? null : MedidaCm(centesimos);
  }

  /// Como [tryParse], mas lança [FormatException] se [texto] não for válido.
  static MedidaCm parse(String texto) =>
      tryParse(texto) ?? (throw FormatException('Medida inválida', texto));

  /// Se a medida é maior que zero, como exigido nas dimensões da peça.
  bool get ehPositiva => centesimos > 0;

  @override
  int compareTo(MedidaCm other) => centesimos.compareTo(other.centesimos);

  /// Medida em pt-BR, sem zeros à direita e sem unidade (ex: `75`, `7,5`,
  /// `0,25`, `1.200`).
  String get formatada {
    final inteiro = centesimos ~/ 100;
    final resto = centesimos.remainder(100).abs();
    final sinal = centesimos < 0 && inteiro == 0 ? '-' : '';
    final parteInteira = '$sinal${_comMilhar(inteiro)}';
    if (resto == 0) return parteInteira;
    final decimal = resto
        .toString()
        .padLeft(2, '0')
        .replaceFirst(RegExp(r'0$'), '');
    return '$parteInteira,$decimal';
  }
}

/// Inteiro com ponto de milhar pt-BR (ex: `1200` → `1.200`).
String _comMilhar(int valor) {
  final digitos = valor.abs().toString();
  final buffer = StringBuffer(valor < 0 ? '-' : '');
  for (var i = 0; i < digitos.length; i++) {
    if (i > 0 && (digitos.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digitos[i]);
  }
  return buffer.toString();
}

/// Serializa [MedidaCm] como `int` de centésimos de cm.
class MedidaCmJsonConverter implements JsonConverter<MedidaCm, int> {
  /// Cria o conversor.
  const MedidaCmJsonConverter();

  @override
  MedidaCm fromJson(int json) => MedidaCm(json);

  @override
  int toJson(MedidaCm object) => object.centesimos;
}
