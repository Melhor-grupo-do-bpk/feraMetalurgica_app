import 'package:fera_metalurgica_app/core/domain/erro_validacao.dart';
import 'package:fera_metalurgica_app/core/domain/validacao_comum.dart';
import 'package:fera_metalurgica_app/features/materiais/domain/material.dart';

/// Regras do material (prompt §6): nome obrigatório e preço de referência
/// maior que zero. A unidade é sempre m² ou m³ pelo próprio tipo.
List<ErroValidacao> validarMaterial(Material material, {String caminho = ''}) =>
    [
      ...validarTextoObrigatorio(material.nome, juntarCaminho(caminho, 'nome')),
      if (!material.precoReferencia.ehPositivo)
        ErroValidacao(
          caminhoCampo: juntarCaminho(caminho, 'precoReferencia'),
          codigo: CodigoErroValidacao.naoPositivo,
          mensagem: 'O preço de referência deve ser maior que zero',
        ),
    ];
