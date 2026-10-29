import 'package:fera_metalurgica_app/core/domain/documento.dart';
import 'package:fera_metalurgica_app/core/domain/endereco.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'cliente.freezed.dart';
part 'cliente.g.dart';

/// Cadastro de cliente (prompt §3.3). Todos os campos são obrigatórios, e o
/// documento normalizado é a chave única: nome ou telefone iguais não
/// bastam para mesclar pessoas.
///
/// O orçamento guarda uma cópia editável (`ClienteSnapshot`, gerada por
/// `gerarSnapshot()` em `orcamentos/domain/v2/cliente_snapshot.dart`). O
/// cadastro só é criado ou atualizado ao salvar o orçamento.
@freezed
abstract class Cliente with _$Cliente {
  /// Cria um [Cliente].
  const factory Cliente({
    /// Identificador único (UUID).
    required String id,

    /// Nome da pessoa ou empresa.
    required String nome,

    /// CPF ou CNPJ; o tipo (PF/PJ) é deduzido pelos dígitos (D-23).
    @DocumentoJsonConverter() required Documento documento,

    /// Celular com DDD, em texto; é também o número do WhatsApp.
    required String celular,

    /// Endereço.
    required Endereco endereco,
  }) = _Cliente;

  /// Cria um [Cliente] a partir de um mapa JSON.
  factory Cliente.fromJson(Map<String, dynamic> json) =>
      _$ClienteFromJson(json);
}
