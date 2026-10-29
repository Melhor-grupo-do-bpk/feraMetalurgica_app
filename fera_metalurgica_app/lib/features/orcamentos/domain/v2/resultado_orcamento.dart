import 'package:fera_metalurgica_app/core/domain/dinheiro.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/v2/resultado_item.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'resultado_orcamento.freezed.dart';
part 'resultado_orcamento.g.dart';

/// Totais do orçamento (prompt §5 e §7). Gerados pela
/// `CalculadoraOrcamento` e gravados ao salvar: um orçamento salvo mostra
/// estes valores, sem recalcular (D-26).
@freezed
abstract class ResultadoOrcamento with _$ResultadoOrcamento {
  /// Cria um [ResultadoOrcamento].
  const factory ResultadoOrcamento({
    /// Resultado de cada produto, na ordem dos itens.
    required List<ResultadoItem> itens,

    /// Soma do total de cada item.
    @DinheiroJsonConverter() required Dinheiro totalProdutos,

    /// Insumos + impostos + combustível + outros.
    @DinheiroJsonConverter() required Dinheiro totalAdicionais,

    /// [totalProdutos] + [totalAdicionais].
    @DinheiroJsonConverter() required Dinheiro subtotal,

    /// Desconto aplicado sobre o [subtotal].
    @DinheiroJsonConverter() required Dinheiro desconto,

    /// [subtotal] − [desconto]; nunca negativo.
    @DinheiroJsonConverter() required Dinheiro totalGeral,
  }) = _ResultadoOrcamento;

  const ResultadoOrcamento._();

  /// Cria um [ResultadoOrcamento] a partir de um mapa JSON.
  factory ResultadoOrcamento.fromJson(Map<String, dynamic> json) =>
      _$ResultadoOrcamentoFromJson(json);

  /// Se o total geral é zero. É permitido, mas a interface destaca para
  /// conferência (prompt §6); não é erro de validação.
  bool get totalGeralZero => totalGeral.ehZero;
}
