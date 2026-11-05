import 'package:fera_metalurgica_app/core/domain/documento.dart';
import 'package:fera_metalurgica_app/core/domain/endereco.dart';
import 'package:fera_metalurgica_app/features/empresa/empresa.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'empresa_snapshot.freezed.dart';
part 'empresa_snapshot.g.dart';

/// Cópia completa da empresa emitente guardada no orçamento (prompt §7),
/// criada ao iniciar o fluxo e de novo ao salvar uma edição (D-30).
@freezed
abstract class EmpresaSnapshot with _$EmpresaSnapshot {
  /// Cria um [EmpresaSnapshot].
  const factory EmpresaSnapshot({
    /// Nome ou razão social.
    required String nomeRazaoSocial,

    /// CPF ou CNPJ.
    @DocumentoJsonConverter() required Documento documento,

    /// Telefone com DDD, em texto.
    required String telefone,

    /// Endereço.
    required Endereco endereco,

    /// E-mail, quando informado.
    String? email,

    /// Id da `Empresa` de origem, quando houver.
    String? empresaOrigemId,
  }) = _EmpresaSnapshot;

  /// Cria um [EmpresaSnapshot] a partir de um mapa JSON.
  factory EmpresaSnapshot.fromJson(Map<String, dynamic> json) =>
      _$EmpresaSnapshotFromJson(json);
}

/// Cópia de uma [Empresa] para o orçamento.
extension EmpresaGerarSnapshot on Empresa {
  /// Copia todos os dados, com o id como origem.
  EmpresaSnapshot gerarSnapshot() => EmpresaSnapshot(
    empresaOrigemId: id,
    nomeRazaoSocial: nomeRazaoSocial,
    documento: documento,
    telefone: telefone,
    endereco: endereco,
    email: email,
  );
}
