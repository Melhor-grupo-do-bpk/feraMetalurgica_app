import 'package:fera_metalurgica_app/core/domain/unidade_cobranca.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'consumo.freezed.dart';
part 'consumo.g.dart';

final BigInt _escala = BigInt.from(10).pow(Consumo.casasDecimais);

/// Quantidade exata de material (m² ou m³), em escala fixa de 12 casas
/// (D-26): [valor] é o consumo × 10¹². Medidas em centésimos de cm dão
/// sempre um consumo exato nessa escala, sem arredondar.
///
/// No JSON: `{"unidade": "m3", "valor": "0.004800000000"}`, com o valor em
/// texto canônico.
@freezed
abstract class Consumo with _$Consumo {
  /// Cria um [Consumo] com [valor] já na escala de 10¹².
  const factory Consumo({
    /// Unidade do consumo (m² ou m³).
    required UnidadeCobranca unidade,

    /// Consumo multiplicado por 10¹² (ex: 0,0048 m³ → `4800000000`).
    @_EscalaTextoConverter() required BigInt valor,
  }) = _Consumo;

  const Consumo._();

  /// Cria um [Consumo] a partir de um mapa JSON.
  factory Consumo.fromJson(Map<String, dynamic> json) =>
      _$ConsumoFromJson(json);

  /// Consumo zero na [unidade].
  factory Consumo.zero(UnidadeCobranca unidade) =>
      Consumo(unidade: unidade, valor: BigInt.zero);

  /// Casas decimais da escala fixa.
  static const int casasDecimais = 12;

  /// Soma consumos da mesma unidade. Lança [ArgumentError] se as unidades
  /// forem diferentes: m² e m³ nunca se somam.
  Consumo operator +(Consumo outro) {
    if (outro.unidade != unidade) {
      throw ArgumentError.value(
        outro.unidade,
        'outro',
        'Não é possível somar consumo em ${unidade.name} com '
            '${outro.unidade.name}',
      );
    }
    return copyWith(valor: valor + outro.valor);
  }

  /// Multiplica por um inteiro (ex: quantidade de peças).
  Consumo operator *(int fator) => copyWith(valor: valor * BigInt.from(fator));

  /// Texto canônico, com ponto e 12 casas (ex: `"0.004800000000"`).
  String get textoCanonico => _formatarEscala(valor);

  /// Consumo em pt-BR, sem zeros à direita e com até 12 casas (ex:
  /// `0,0048`, `1,62`, `3`). Só para exibição.
  String get formatado {
    final partes = _formatarEscala(valor).split('.');
    final decimal = partes[1].replaceFirst(RegExp(r'0+$'), '');
    return decimal.isEmpty ? partes[0] : '${partes[0]},$decimal';
  }

  /// Consumo com o símbolo da unidade (ex: `0,0048 m³`).
  String get formatadoComUnidade =>
      '$formatado ${unidade == UnidadeCobranca.m2 ? 'm²' : 'm³'}';
}

String _formatarEscala(BigInt valor) {
  final sinal = valor.isNegative ? '-' : '';
  final absoluto = valor.abs();
  final inteiro = absoluto ~/ _escala;
  final decimal = (absoluto % _escala).toString().padLeft(
    Consumo.casasDecimais,
    '0',
  );
  return '$sinal$inteiro.$decimal';
}

final RegExp _textoCanonico = RegExp(r'^(-?)(\d+)\.(\d{12})$');

class _EscalaTextoConverter implements JsonConverter<BigInt, String> {
  const _EscalaTextoConverter();

  @override
  BigInt fromJson(String json) {
    final match = _textoCanonico.firstMatch(json);
    if (match == null) {
      throw FormatException('Consumo fora do texto canônico', json);
    }
    final absoluto =
        BigInt.parse(match.group(2)!) * _escala + BigInt.parse(match.group(3)!);
    return match.group(1)!.isEmpty ? absoluto : -absoluto;
  }

  @override
  String toJson(BigInt object) => _formatarEscala(object);
}
