import 'package:fera_metalurgica_app/core/utils/validators.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'cliente.freezed.dart';
part 'cliente.g.dart';

/// Etapa 1 do wizard de orçamento: dados do cliente.
@freezed
abstract class Cliente with _$Cliente {
  /// Cria um [Cliente].
  const factory Cliente({
    /// Identificador único do cliente.
    required String id,

    /// Nome do cliente ou da empresa contratante.
    required String nome,

    /// Número de telefone/WhatsApp do cliente.
    required String numero,

    /// CPF ou CNPJ do cliente.
    required String cpfCnpj,

    /// E-mail de contato do cliente, quando informado.
    String? email,

    /// Observações adicionais sobre o cliente.
    String? observacoes,
  }) = _Cliente;

  const Cliente._();

  /// Cria um [Cliente] a partir de um mapa JSON.
  factory Cliente.fromJson(Map<String, dynamic> json) =>
      _$ClienteFromJson(json);

  /// Se o cliente é pessoa jurídica: [cpfCnpj] com 14 dígitos (CNPJ).
  /// Qualquer outro valor conta como pessoa física (D-23).
  bool get ehPessoaJuridica => somenteDigitos(cpfCnpj).length == 14;
}
