import 'package:freezed_annotation/freezed_annotation.dart';

/// Unidade em que um material é cobrado (prompt §3.1).
///
/// Serializada pelo NOME (`"m2"`, `"m3"`), nunca pelo índice. Outra unidade
/// exigiria nova estratégia de cálculo e validação na
/// `CalculadoraOrcamento`.
@JsonEnum()
enum UnidadeCobranca {
  /// Metro quadrado: consumo = comprimento × largura.
  m2,

  /// Metro cúbico: consumo = comprimento × largura × espessura.
  m3,
}
