import 'package:fera_metalurgica_app/core/domain/documento.dart';
import 'package:fera_metalurgica_app/core/domain/endereco.dart';
import 'package:fera_metalurgica_app/features/clientes/clientes.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'cliente_snapshot.freezed.dart';
part 'cliente_snapshot.g.dart';

/// Cópia completa do cliente guardada no orçamento (prompt §7). Na edição,
/// é a cópia editável da etapa 1; o cadastro só muda ao salvar. A origem
/// serve para rastreio: ausente, não invalida a cópia.
@freezed
abstract class ClienteSnapshot with _$ClienteSnapshot {
  /// Cria um [ClienteSnapshot].
  const factory ClienteSnapshot({
    /// Nome da pessoa ou empresa.
    required String nome,

    /// CPF ou CNPJ.
    @DocumentoJsonConverter() required Documento documento,

    /// Celular com DDD (WhatsApp), em texto.
    required String celular,

    /// Endereço.
    required Endereco endereco,

    /// Id do `Cliente` de origem, quando houver.
    String? clienteOrigemId,
  }) = _ClienteSnapshot;

  /// Cria um [ClienteSnapshot] a partir de um mapa JSON.
  factory ClienteSnapshot.fromJson(Map<String, dynamic> json) =>
      _$ClienteSnapshotFromJson(json);
}

/// Cópia de um [Cliente] para o orçamento.
extension ClienteGerarSnapshot on Cliente {
  /// Copia todos os dados, com o id como origem.
  ClienteSnapshot gerarSnapshot() => ClienteSnapshot(
    clienteOrigemId: id,
    nome: nome,
    documento: documento,
    celular: celular,
    endereco: endereco,
  );
}
