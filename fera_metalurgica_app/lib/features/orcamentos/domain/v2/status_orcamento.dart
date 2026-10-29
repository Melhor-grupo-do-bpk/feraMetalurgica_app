import 'package:freezed_annotation/freezed_annotation.dart';

/// Status de um orçamento salvo (D-29).
///
/// Serializado pelo NOME (ex: `"criado"`), nunca pelo índice. Não renomeie
/// valores existentes sem migrar os dados.
@JsonEnum()
enum StatusOrcamento {
  /// Salvo e ainda não enviado. Editar um orçamento enviado o traz de volta
  /// para cá (D-30).
  criado,

  /// Enviado ao cliente (pelo WhatsApp, ou marcado à mão nos detalhes).
  enviado,
}
