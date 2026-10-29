import 'package:fera_metalurgica_app/core/domain/dinheiro.dart';
import 'package:fera_metalurgica_app/features/materiais/materiais.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'material_snapshot.freezed.dart';
part 'material_snapshot.g.dart';

/// Cópia do material usada numa peça (prompt §7). Imutável: ajustar o preço
/// cria uma nova cópia. Mudar ou inativar o cadastro depois não altera a
/// peça. O vínculo de origem serve só para rastreio, nunca para recalcular.
@freezed
abstract class MaterialSnapshot with _$MaterialSnapshot {
  /// Cria um [MaterialSnapshot].
  const factory MaterialSnapshot({
    /// Nome copiado do cadastro.
    required String nome,

    /// Unidade copiada do cadastro.
    required UnidadeCobranca unidade,

    /// Preço de referência do cadastro no momento da cópia.
    @DinheiroJsonConverter() required Dinheiro precoReferenciaCopiado,

    /// Preço usado no cálculo da peça; começa igual ao copiado e pode ser
    /// ajustado só na peça, sem voltar ao cadastro.
    @DinheiroJsonConverter() required Dinheiro precoAplicado,

    /// Id do `Material` de origem, quando houver.
    String? materialOrigemId,
  }) = _MaterialSnapshot;

  const MaterialSnapshot._();

  /// Cria um [MaterialSnapshot] a partir de um mapa JSON.
  factory MaterialSnapshot.fromJson(Map<String, dynamic> json) =>
      _$MaterialSnapshotFromJson(json);

  /// Se o preço aplicado difere do copiado do cadastro (a interface sinaliza
  /// o ajuste).
  bool get precoAjustado => precoAplicado != precoReferenciaCopiado;
}

/// Cópia de um [Material] para uma peça.
extension MaterialGerarSnapshot on Material {
  /// Copia nome, unidade e preço; o preço aplicado começa igual ao de
  /// referência.
  MaterialSnapshot gerarSnapshot() => MaterialSnapshot(
    materialOrigemId: id,
    nome: nome,
    unidade: unidade,
    precoReferenciaCopiado: precoReferencia,
    precoAplicado: precoReferencia,
  );
}
