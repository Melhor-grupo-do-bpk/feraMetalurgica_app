import 'package:fera_metalurgica_app/core/utils/validators.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'endereco.freezed.dart';
part 'endereco.g.dart';

/// Endereço de cliente ou empresa (prompt §7). A validação fica em
/// `validarEndereco` (`core/domain/validacao_comum.dart`).
@freezed
abstract class Endereco with _$Endereco {
  /// Cria um [Endereco].
  const factory Endereco({
    /// Rua, avenida etc.
    required String logradouro,

    /// Número, em texto: aceita "s/n".
    required String numero,

    /// Bairro.
    required String bairro,

    /// Cidade.
    required String cidade,

    /// Sigla do estado, com 2 letras maiúsculas (ex: `PR`).
    required String uf,

    /// CEP, com ou sem máscara, quando informado.
    String? cep,

    /// Complemento (ex: "Sala 2"), quando informado.
    String? complemento,
  }) = _Endereco;

  const Endereco._();

  /// Cria um [Endereco] a partir de um mapa JSON.
  factory Endereco.fromJson(Map<String, dynamic> json) =>
      _$EnderecoFromJson(json);

  /// Endereço em uma linha (ex: `Rua das Flores, 123, Sala 2 - Centro,
  /// Curitiba/PR, CEP 80010-000`). Partes opcionais vazias são omitidas.
  String get formatado {
    final rua = _juntar([logradouro, numero, complemento], ', ');
    final cidadeUf = _juntar([cidade, uf], '/');
    final local = _juntar([bairro, cidadeUf], ', ');
    final cepFormatado = _formatarCep(cep);
    return _juntar([
      _juntar([rua, local], ' - '),
      if (cepFormatado.isNotEmpty) 'CEP $cepFormatado',
    ], ', ');
  }
}

/// Junta as [partes] preenchidas (sem espaços nas pontas) com [separador].
String _juntar(List<String?> partes, String separador) => partes
    .map((p) => p?.trim() ?? '')
    .where((p) => p.isNotEmpty)
    .join(separador);

String _formatarCep(String? cep) {
  if (cep == null) return '';
  final digitos = somenteDigitos(cep);
  if (digitos.length != 8) return cep.trim();
  return '${digitos.substring(0, 5)}-${digitos.substring(5)}';
}
