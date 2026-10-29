import 'package:fera_metalurgica_app/core/domain/consumo.dart';
import 'package:fera_metalurgica_app/core/domain/dinheiro.dart';
import 'package:fera_metalurgica_app/core/domain/unidade_cobranca.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'resultado_peca.freezed.dart';
part 'resultado_peca.g.dart';

/// Cálculo de uma linha de peça, para UM produto (prompt §5 e §7). Gerado
/// pela `CalculadoraOrcamento` e gravado com o orçamento.
@freezed
abstract class ResultadoPeca with _$ResultadoPeca {
  /// Cria um [ResultadoPeca].
  const factory ResultadoPeca({
    /// Id da `PecaOrcamento` calculada.
    required String pecaId,

    /// Consumo exato de uma peça.
    required Consumo consumoUnitario,

    /// Consumo da linha: [consumoUnitario] × quantidade por produto.
    required Consumo consumoLinha,

    /// Custo de uma peça, arredondado half-up para centavos (o único
    /// arredondamento do cálculo).
    @DinheiroJsonConverter() required Dinheiro custoUnitario,

    /// Custo da linha: [custoUnitario] × quantidade por produto.
    @DinheiroJsonConverter() required Dinheiro custoLinha,
  }) = _ResultadoPeca;

  const ResultadoPeca._();

  /// Cria um [ResultadoPeca] a partir de um mapa JSON.
  factory ResultadoPeca.fromJson(Map<String, dynamic> json) =>
      _$ResultadoPecaFromJson(json);

  /// Unidade do consumo (a do material da peça).
  UnidadeCobranca get unidade => consumoUnitario.unidade;
}
