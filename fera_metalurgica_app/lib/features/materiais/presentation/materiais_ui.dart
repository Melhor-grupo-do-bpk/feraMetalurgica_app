import 'package:fera_metalurgica_app/core/domain/unidade_cobranca.dart';

/// Textos de [UnidadeCobranca] para a UI.
extension UnidadeCobrancaUi on UnidadeCobranca {
  /// Símbolo da unidade (ex: "m²").
  String get simbolo => switch (this) {
    UnidadeCobranca.m2 => 'm²',
    UnidadeCobranca.m3 => 'm³',
  };
}
