import 'package:fera_metalurgica_app/core/domain/documento.dart';
import 'package:fera_metalurgica_app/core/domain/endereco.dart';
import 'package:fera_metalurgica_app/core/domain/erro_validacao.dart';
import 'package:fera_metalurgica_app/core/domain/validacao_comum.dart';
import 'package:fera_metalurgica_app/features/clientes/domain/cliente.dart';

/// Regras do cliente (prompt §3.3 e §6), campo a campo, para valer tanto no
/// cadastro ([validarCliente]) quanto na cópia guardada no orçamento
/// (`ClienteSnapshot`).
List<ErroValidacao> validarDadosCliente({
  required String nome,
  required Documento documento,
  required String celular,
  required Endereco endereco,
  String caminho = '',
}) {
  String c(String campo) => juntarCaminho(caminho, campo);
  return [
    ...validarTextoObrigatorio(nome, c('nome')),
    ...validarDocumento(documento, caminho: c('documento')),
    ...validarTelefoneObrigatorio(celular, c('celular')),
    ...validarEndereco(endereco, caminho: c('endereco')),
  ];
}

/// Valida o cadastro do cliente.
List<ErroValidacao> validarCliente(Cliente cliente, {String caminho = ''}) =>
    validarDadosCliente(
      nome: cliente.nome,
      documento: cliente.documento,
      celular: cliente.celular,
      endereco: cliente.endereco,
      caminho: caminho,
    );
