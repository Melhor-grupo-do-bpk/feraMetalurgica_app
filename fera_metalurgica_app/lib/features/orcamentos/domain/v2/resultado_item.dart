import 'package:fera_metalurgica_app/core/domain/dinheiro.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/v2/resultado_peca.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'resultado_item.freezed.dart';
part 'resultado_item.g.dart';

/// Cálculo de um produto (prompt §5 e §7). Gerado pela
/// `CalculadoraOrcamento` e gravado com o orçamento.
@freezed
abstract class ResultadoItem with _$ResultadoItem {
  /// Cria um [ResultadoItem].
  const factory ResultadoItem({
    /// Id do `ItemOrcamento` calculado.
    required String itemId,

    /// Resultado de cada peça, na ordem das peças.
    required List<ResultadoPeca> pecas,

    /// Soma do custo das linhas de peça (um produto).
    @DinheiroJsonConverter() required Dinheiro custoMateriais,

    /// [custoMateriais] + preço base (um produto).
    @DinheiroJsonConverter() required Dinheiro precoUnitario,

    /// [precoUnitario] × quantidade de produtos.
    @DinheiroJsonConverter() required Dinheiro totalItem,
  }) = _ResultadoItem;

  /// Cria um [ResultadoItem] a partir de um mapa JSON.
  factory ResultadoItem.fromJson(Map<String, dynamic> json) =>
      _$ResultadoItemFromJson(json);
}
