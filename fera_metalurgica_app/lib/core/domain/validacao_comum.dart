// Validações de domínio usadas por mais de uma feature (cliente, empresa,
// orçamento). Cada função devolve a lista de `ErroValidacao` encontrados,
// vazia se tudo estiver certo, e nunca altera os dados. As mensagens e
// regras de CPF/CNPJ, telefone e e-mail vêm de `core/utils/validators.dart`.

import 'package:fera_metalurgica_app/core/domain/documento.dart';
import 'package:fera_metalurgica_app/core/domain/endereco.dart';
import 'package:fera_metalurgica_app/core/domain/erro_validacao.dart';
import 'package:fera_metalurgica_app/core/utils/validators.dart';

final RegExp _uf = RegExp(r'^[A-Z]{2}$');

/// Erro `obrigatorio` em [caminho] se [valor] estiver vazio ou só com
/// espaços.
List<ErroValidacao> validarTextoObrigatorio(String? valor, String caminho) {
  final mensagem = validarObrigatorio(valor);
  return [
    if (mensagem != null)
      ErroValidacao(
        caminhoCampo: caminho,
        codigo: CodigoErroValidacao.obrigatorio,
        mensagem: mensagem,
      ),
  ];
}

/// CPF ou CNPJ obrigatório e com dígitos verificadores corretos, conforme o
/// tipo deduzido pela quantidade de dígitos (D-23).
List<ErroValidacao> validarDocumento(
  Documento documento, {
  String caminho = 'documento',
}) {
  final valor = documento.valorNormalizado;
  if (valor.isEmpty) return validarTextoObrigatorio(valor, caminho);
  final mensagem = validarCpfCnpj(valor);
  return [
    if (mensagem != null)
      ErroValidacao(
        caminhoCampo: caminho,
        codigo: CodigoErroValidacao.invalido,
        mensagem: mensagem,
      ),
  ];
}

/// Telefone ou celular obrigatório, com DDD (10 ou 11 dígitos). Texto,
/// nunca número.
List<ErroValidacao> validarTelefoneObrigatorio(String valor, String caminho) {
  if (valor.trim().isEmpty) return validarTextoObrigatorio(valor, caminho);
  final mensagem = validarTelefone(valor);
  return [
    if (mensagem != null)
      ErroValidacao(
        caminhoCampo: caminho,
        codigo: CodigoErroValidacao.invalido,
        mensagem: mensagem,
      ),
  ];
}

/// E-mail opcional: vazio é aceito; preenchido precisa ter formato válido.
List<ErroValidacao> validarEmailOpcional(String? valor, String caminho) {
  final mensagem = validarEmail(valor);
  return [
    if (mensagem != null)
      ErroValidacao(
        caminhoCampo: caminho,
        codigo: CodigoErroValidacao.invalido,
        mensagem: mensagem,
      ),
  ];
}

/// Endereço com logradouro, número, bairro e cidade preenchidos, UF com 2
/// letras maiúsculas e CEP, se informado, com 8 dígitos.
List<ErroValidacao> validarEndereco(
  Endereco endereco, {
  String caminho = 'endereco',
}) {
  String c(String campo) => juntarCaminho(caminho, campo);
  final uf = endereco.uf;
  final cep = endereco.cep?.trim() ?? '';
  return [
    ...validarTextoObrigatorio(endereco.logradouro, c('logradouro')),
    ...validarTextoObrigatorio(endereco.numero, c('numero')),
    ...validarTextoObrigatorio(endereco.bairro, c('bairro')),
    ...validarTextoObrigatorio(endereco.cidade, c('cidade')),
    if (uf.trim().isEmpty)
      ...validarTextoObrigatorio(uf, c('uf'))
    else if (!_uf.hasMatch(uf))
      ErroValidacao(
        caminhoCampo: c('uf'),
        codigo: CodigoErroValidacao.invalido,
        mensagem: 'UF inválida: use a sigla com 2 letras maiúsculas',
      ),
    if (cep.isNotEmpty && somenteDigitos(cep).length != 8)
      ErroValidacao(
        caminhoCampo: c('cep'),
        codigo: CodigoErroValidacao.invalido,
        mensagem: 'CEP inválido: informe 8 dígitos',
      ),
  ];
}
