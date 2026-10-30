import 'package:fera_metalurgica_app/core/domain/documento.dart';
import 'package:fera_metalurgica_app/core/domain/endereco.dart';
import 'package:fera_metalurgica_app/features/empresa/domain/empresa.dart';

/// Empresa de exemplo dos dados de debug (D-17), com os dados do emissor
/// das telas do Figma. Completa, para liberar o "Novo orçamento".
const Empresa empresaExemplo = Empresa(
  id: 'empresa-exemplo',
  nomeRazaoSocial: 'Fera Metalúrgica Ltda',
  documento: Documento('11444777000161'),
  telefone: '(11) 3333-4444',
  email: 'contato@ferametalurgica.com.br',
  endereco: Endereco(
    logradouro: 'Av. Industrial',
    numero: '1000',
    complemento: 'Galpão 4',
    bairro: 'Distrito Industrial',
    cidade: 'São Paulo',
    uf: 'SP',
  ),
);
