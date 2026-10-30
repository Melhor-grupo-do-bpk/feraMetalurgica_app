import 'package:fera_metalurgica_app/core/domain/medida_cm.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/material_snapshot.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'peca_orcamento.freezed.dart';
part 'peca_orcamento.g.dart';

/// Componente físico usado para fabricar UMA unidade do produto (prompt
/// §3.4). Uma linha pode representar várias peças idênticas
/// ([quantidadePorProduto]). Cada peça tem exatamente um material: dois
/// materiais são duas linhas.
///
/// Só entra no item depois de validada (`validarPeca`). Para alterar, use
/// `copyWith`.
@freezed
abstract class PecaOrcamento with _$PecaOrcamento {
  /// Cria uma [PecaOrcamento].
  const factory PecaOrcamento({
    /// Identificador único (UUID), novo a cada duplicação.
    required String id,

    /// Descrição (ex: "Tampo", "Perna").
    required String descricao,

    /// Quantas peças iguais vão em um produto (≥ 1).
    required int quantidadePorProduto,

    /// Material copiado, com o preço aplicado.
    required MaterialSnapshot material,

    /// Comprimento, em cm.
    @MedidaCmJsonConverter() required MedidaCm comprimentoCm,

    /// Largura, em cm.
    @MedidaCmJsonConverter() required MedidaCm larguraCm,

    /// Espessura, em cm: obrigatória em m³; em m² é só informativa, sem
    /// efeito no cálculo.
    @MedidaCmJsonConverter() MedidaCm? espessuraCm,

    /// Observações, quando informadas.
    String? observacoes,
  }) = _PecaOrcamento;

  const PecaOrcamento._();

  /// Cria uma [PecaOrcamento] a partir de um mapa JSON.
  factory PecaOrcamento.fromJson(Map<String, dynamic> json) =>
      _$PecaOrcamentoFromJson(json);

  /// Cópia independente com o identificador [novoId].
  PecaOrcamento duplicar(String novoId) => copyWith(id: novoId);
}
