import 'package:fera_metalurgica_app/core/domain/documento.dart';
import 'package:fera_metalurgica_app/core/domain/endereco.dart';
import 'package:fera_metalurgica_app/core/domain/erro_validacao.dart';
import 'package:fera_metalurgica_app/core/domain/validacao_comum.dart';
import 'package:fera_metalurgica_app/features/empresa/domain/empresa.dart';

/// Regras dos dados da empresa (prompt §3.2), campo a campo, para valer
/// tanto no cadastro ([validarEmpresa]) quanto na cópia guardada no
/// orçamento (`EmpresaSnapshot`).
List<ErroValidacao> validarDadosEmpresa({
  required String nomeRazaoSocial,
  required Documento documento,
  required String telefone,
  required Endereco endereco,
  String? email,
  String caminho = '',
}) {
  String c(String campo) => juntarCaminho(caminho, campo);
  return [
    ...validarTextoObrigatorio(nomeRazaoSocial, c('nomeRazaoSocial')),
    ...validarDocumento(documento, caminho: c('documento')),
    ...validarTelefoneObrigatorio(telefone, c('telefone')),
    ...validarEndereco(endereco, caminho: c('endereco')),
    ...validarEmailOpcional(email, c('email')),
  ];
}

/// Valida o cadastro da empresa.
List<ErroValidacao> validarEmpresa(Empresa empresa, {String caminho = ''}) =>
    validarDadosEmpresa(
      nomeRazaoSocial: empresa.nomeRazaoSocial,
      documento: empresa.documento,
      telefone: empresa.telefone,
      endereco: empresa.endereco,
      email: empresa.email,
      caminho: caminho,
    );
