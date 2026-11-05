import 'package:fera_metalurgica_app/core/utils/input_formatters.dart';
import 'package:fera_metalurgica_app/core/utils/validators.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'documento.freezed.dart';

/// Tipo de um [Documento], deduzido pela quantidade de dígitos (D-23).
enum TipoDocumento {
  /// Pessoa física (11 dígitos).
  cpf,

  /// Pessoa jurídica (14 dígitos).
  cnpj,
}

/// CPF ou CNPJ, guardado só com os dígitos. O documento normalizado é a
/// chave única do cliente (prompt §3.3). É texto, nunca número: zeros à
/// esquerda importam.
///
/// No JSON é o texto normalizado (ver [DocumentoJsonConverter]). A validação
/// fica em `validarDocumento` (`core/domain/validacao_comum.dart`).
@freezed
abstract class Documento with _$Documento {
  /// Cria um [Documento] com [valorNormalizado] já sem máscara. Para texto
  /// digitado, use [Documento.deTexto].
  const factory Documento(String valorNormalizado) = _Documento;

  const Documento._();

  /// Normaliza [texto] (com ou sem máscara) para só dígitos.
  factory Documento.deTexto(String texto) => Documento(somenteDigitos(texto));

  /// CNPJ com 14 dígitos; qualquer outra quantidade conta como CPF (D-23).
  TipoDocumento get tipo =>
      valorNormalizado.length == 14 ? TipoDocumento.cnpj : TipoDocumento.cpf;

  /// Se é pessoa jurídica (CNPJ).
  bool get ehPessoaJuridica => tipo == TipoDocumento.cnpj;

  /// Documento com máscara (ex: `529.982.247-25`, `11.222.333/0001-81`).
  String get formatado => formatarCpfCnpj(valorNormalizado);
}

/// Serializa [Documento] como o texto normalizado.
class DocumentoJsonConverter implements JsonConverter<Documento, String> {
  /// Cria o conversor.
  const DocumentoJsonConverter();

  @override
  Documento fromJson(String json) => Documento(json);

  @override
  String toJson(Documento object) => object.valorNormalizado;
}
