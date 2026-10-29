import 'package:fera_metalurgica_app/core/domain/dinheiro.dart';
import 'package:fera_metalurgica_app/core/domain/unidade_cobranca.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'material.freezed.dart';
part 'material.g.dart';

/// Matéria-prima de referência (prompt §3.1), ex: "Granito - variedade B -
/// 2 cm". O nome identifica a variação que muda o preço.
///
/// Ao entrar numa peça, o material é copiado (`MaterialSnapshot`, gerado por
/// `gerarSnapshot()` em `orcamentos/domain/v2/material_snapshot.dart`):
/// mudar o cadastro depois não altera orçamentos. Para trocar a unidade de
/// uma referência já usada, cadastre outra e inative esta.
@freezed
abstract class Material with _$Material {
  /// Cria um [Material].
  const factory Material({
    /// Identificador único (UUID).
    required String id,

    /// Nome que identifica a variação (espécie, acabamento, espessura).
    required String nome,

    /// Unidade de cobrança (m² ou m³).
    required UnidadeCobranca unidade,

    /// Preço de referência por unidade, maior que zero. Não é média
    /// calculada: é o valor sugerido ao selecionar o material.
    @DinheiroJsonConverter() required Dinheiro precoReferencia,

    /// Se aparece em novas seleções. Inativar substitui a exclusão.
    @Default(true) bool ativo,
  }) = _Material;

  /// Cria um [Material] a partir de um mapa JSON.
  factory Material.fromJson(Map<String, dynamic> json) =>
      _$MaterialFromJson(json);
}
