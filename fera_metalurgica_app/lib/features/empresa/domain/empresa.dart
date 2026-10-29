import 'package:fera_metalurgica_app/core/domain/documento.dart';
import 'package:fera_metalurgica_app/core/domain/endereco.dart';
import 'package:fera_metalurgica_app/features/empresa/domain/validacao_empresa.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'empresa.freezed.dart';
part 'empresa.g.dart';

/// Dados da empresa emitente (prompt §3.2): um registro por instalação.
/// Sem os obrigatórios ([estaCompleta] falso), "Novo orçamento" fica
/// bloqueado.
///
/// O orçamento guarda uma cópia (`EmpresaSnapshot`, gerada por
/// `gerarSnapshot()` em `orcamentos/domain/v2/empresa_snapshot.dart`).
@freezed
abstract class Empresa with _$Empresa {
  /// Cria uma [Empresa].
  const factory Empresa({
    /// Identificador único (UUID).
    required String id,

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
  }) = _Empresa;

  const Empresa._();

  /// Cria uma [Empresa] a partir de um mapa JSON.
  factory Empresa.fromJson(Map<String, dynamic> json) =>
      _$EmpresaFromJson(json);

  /// Se todos os dados obrigatórios estão preenchidos e válidos.
  bool get estaCompleta => validarDadosEmpresa(
    nomeRazaoSocial: nomeRazaoSocial,
    documento: documento,
    telefone: telefone,
    endereco: endereco,
    email: email,
  ).isEmpty;
}
