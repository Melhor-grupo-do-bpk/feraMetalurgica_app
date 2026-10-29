import 'package:fera_metalurgica_app/core/domain/decimal_pt_br.dart';
import 'package:fera_metalurgica_app/core/utils/currency_format.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'dinheiro.freezed.dart';

final RegExp _prefixoReal = RegExp(r'^R\$\s*');

/// Valor monetário exato, em centavos (D-26). Nunca use `double` em
/// cálculo com dinheiro: some, subtraia e multiplique por inteiros aqui.
///
/// No JSON é um `int` de centavos (ver [DinheiroJsonConverter]).
@freezed
abstract class Dinheiro with _$Dinheiro implements Comparable<Dinheiro> {
  /// Cria um [Dinheiro] com [centavos] (ex: `Dinheiro(845000)` é
  /// R$ 8.450,00).
  const factory Dinheiro(int centavos) = _Dinheiro;

  const Dinheiro._();

  /// Lê um valor digitado em pt-BR, com ou sem `R$` (ex: `"1.234,56"`,
  /// `"1234,5"`, `"R$ 10"`, `"7.50"`), sem passar por `double`.
  ///
  /// Devolve `null` para texto vazio, valor negativo, mais de duas casas
  /// decimais ou texto inválido. As regras de ponto e vírgula estão em
  /// [lerCentesimosPtBr].
  static Dinheiro? tryParse(String texto) {
    final centavos = lerCentesimosPtBr(
      texto.trim().replaceFirst(_prefixoReal, ''),
    );
    return centavos == null ? null : Dinheiro(centavos);
  }

  /// Como [tryParse], mas lança [FormatException] se [texto] não for válido.
  static Dinheiro parse(String texto) =>
      tryParse(texto) ??
      (throw FormatException('Valor monetário inválido', texto));

  /// R$ 0,00.
  static const Dinheiro zero = Dinheiro(0);

  /// Se o valor é exatamente zero.
  bool get ehZero => centavos == 0;

  /// Se o valor é menor que zero.
  bool get ehNegativo => centavos < 0;

  /// Se o valor é maior que zero.
  bool get ehPositivo => centavos > 0;

  /// Soma.
  Dinheiro operator +(Dinheiro outro) => Dinheiro(centavos + outro.centavos);

  /// Subtração (pode ficar negativa; quem valida é a regra de negócio).
  Dinheiro operator -(Dinheiro outro) => Dinheiro(centavos - outro.centavos);

  /// Multiplicação por um inteiro (ex: quantidade).
  Dinheiro operator *(int fator) => Dinheiro(centavos * fator);

  /// Se é menor que [outro].
  bool operator <(Dinheiro outro) => centavos < outro.centavos;

  /// Se é menor ou igual a [outro].
  bool operator <=(Dinheiro outro) => centavos <= outro.centavos;

  /// Se é maior que [outro].
  bool operator >(Dinheiro outro) => centavos > outro.centavos;

  /// Se é maior ou igual a [outro].
  bool operator >=(Dinheiro outro) => centavos >= outro.centavos;

  @override
  int compareTo(Dinheiro other) => centavos.compareTo(other.centavos);

  /// Valor em pt-BR com símbolo (ex: `R$ 1.234,56`). Só para exibição:
  /// nunca use o texto formatado como entrada de cálculo.
  // A conversão para double é só para reaproveitar `formatarMoeda`; é exata
  // na exibição com duas casas para qualquer valor abaixo de 2^53 centavos.
  String get formatado => formatarMoeda(centavos / 100);

  /// Valor em pt-BR sem símbolo (ex: `1.234,56`), para preencher campos.
  String get formatadoSemSimbolo => formatarNumeroMoeda(centavos / 100);
}

/// Serializa [Dinheiro] como `int` de centavos.
class DinheiroJsonConverter implements JsonConverter<Dinheiro, int> {
  /// Cria o conversor.
  const DinheiroJsonConverter();

  @override
  Dinheiro fromJson(int json) => Dinheiro(json);

  @override
  int toJson(Dinheiro object) => object.centavos;
}
