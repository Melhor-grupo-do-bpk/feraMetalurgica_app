import 'package:fera_metalurgica_app/core/domain/dinheiro.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/peca_orcamento.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'item_orcamento.freezed.dart';
part 'item_orcamento.g.dart';

/// Produto vendido ao cliente (na interface, "Produto"; prompt §3.4): preço
/// base de fabricação por unidade mais o material das [pecas].
///
/// [quantidadeProdutos] só multiplica o resultado final do produto; nunca
/// altera a `quantidadePorProduto` das peças. Só entra no orçamento depois
/// de validado (`validarItem`).
@freezed
abstract class ItemOrcamento with _$ItemOrcamento {
  /// Cria um [ItemOrcamento].
  const factory ItemOrcamento({
    /// Identificador único (UUID), novo a cada duplicação.
    required String id,

    /// Descrição do produto (ex: "Mesa de jantar sob medida").
    required String descricao,

    /// Quantos produtos iguais são vendidos (≥ 1).
    required int quantidadeProdutos,

    /// Preço base de fabricação por produto, sem materiais (≥ 0).
    @DinheiroJsonConverter() required Dinheiro precoBase,

    /// Peças de uma unidade do produto (pelo menos uma), na ordem exibida.
    required List<PecaOrcamento> pecas,

    /// Observações, quando informadas.
    String? observacoes,
  }) = _ItemOrcamento;

  const ItemOrcamento._();

  /// Cria um [ItemOrcamento] a partir de um mapa JSON.
  factory ItemOrcamento.fromJson(Map<String, dynamic> json) =>
      _$ItemOrcamentoFromJson(json);

  /// Cópia profunda: o item e cada peça recebem um id novo de [gerarId]
  /// (ex: `gerarId` de `core/utils/id_generator.dart`). Editar a cópia não
  /// muda o original.
  ItemOrcamento duplicarComNovosIds(String Function() gerarId) => copyWith(
    id: gerarId(),
    pecas: [for (final peca in pecas) peca.duplicar(gerarId())],
  );
}
