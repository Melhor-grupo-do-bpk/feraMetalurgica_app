// Dados de teste da rodada v2 (prompt §9), compartilhados pelos testes de
// `test/unit/v2/`. Os preços são fictícios.

import 'package:fera_metalurgica_app/core/domain/dinheiro.dart';
import 'package:fera_metalurgica_app/core/domain/documento.dart';
import 'package:fera_metalurgica_app/core/domain/endereco.dart';
import 'package:fera_metalurgica_app/features/clientes/clientes.dart';
import 'package:fera_metalurgica_app/features/empresa/empresa.dart';
import 'package:fera_metalurgica_app/features/materiais/materiais.dart';

const enderecoTeste = Endereco(
  logradouro: 'Rua das Flores',
  numero: '123',
  bairro: 'Centro',
  cidade: 'Curitiba',
  uf: 'PR',
  cep: '80010-000',
);

const empresaTeste = Empresa(
  id: 'empresa-1',
  nomeRazaoSocial: 'Fera Metalúrgica Ltda',
  documento: Documento('11222333000181'),
  telefone: '(41) 3333-4444',
  endereco: enderecoTeste,
  email: 'contato@fera.com.br',
);

const clienteTeste = Cliente(
  id: 'cliente-1',
  nome: 'João da Silva',
  documento: Documento('52998224725'),
  celular: '(41) 99999-8888',
  endereco: enderecoTeste,
);

const granito = Material(
  id: 'material-granito',
  nome: 'Granito - variedade B - 2 cm',
  unidade: UnidadeCobranca.m2,
  precoReferencia: Dinheiro(30000),
);

const madeira = Material(
  id: 'material-madeira',
  nome: 'Madeira - espécie A',
  unidade: UnidadeCobranca.m3,
  precoReferencia: Dinheiro(350000),
);

const mdf = Material(
  id: 'material-mdf',
  nome: 'MDF 15 mm',
  unidade: UnidadeCobranca.m2,
  precoReferencia: Dinheiro(9000),
);
