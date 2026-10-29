// Dados de teste da rodada v2 (prompt §9), compartilhados pelos testes de
// `test/unit/v2/`. Os preços são fictícios.

import 'package:fera_metalurgica_app/core/domain/dinheiro.dart';
import 'package:fera_metalurgica_app/core/domain/documento.dart';
import 'package:fera_metalurgica_app/core/domain/endereco.dart';
import 'package:fera_metalurgica_app/core/domain/medida_cm.dart';
import 'package:fera_metalurgica_app/features/clientes/clientes.dart';
import 'package:fera_metalurgica_app/features/empresa/empresa.dart';
import 'package:fera_metalurgica_app/features/materiais/materiais.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/v2/cliente_snapshot.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/v2/empresa_snapshot.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/v2/item_orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/v2/material_snapshot.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/v2/orcamento_em_edicao.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/v2/peca_orcamento.dart';

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

/// Peça com medidas digitadas em pt-BR (ex: `'7,5'`).
PecaOrcamento peca({
  required String id,
  required MaterialSnapshot material,
  required String comprimento,
  required String largura,
  String? espessura,
  int quantidade = 1,
  String descricao = 'Peça',
}) => PecaOrcamento(
  id: id,
  descricao: descricao,
  quantidadePorProduto: quantidade,
  material: material,
  comprimentoCm: MedidaCm.parse(comprimento),
  larguraCm: MedidaCm.parse(largura),
  espessuraCm: espessura == null ? null : MedidaCm.parse(espessura),
);

/// Exemplo A (prompt §9): 2 mesas, base R$ 800,00, tampo de granito
/// 180 × 90 e 4 pernas de madeira 75 × 8 × 8.
final ItemOrcamento itemA = ItemOrcamento(
  id: 'item-a',
  descricao: 'Mesa de jantar sob medida',
  quantidadeProdutos: 2,
  precoBase: Dinheiro.parse('800,00'),
  pecas: [
    peca(
      id: 'tampo',
      descricao: 'Tampo',
      material: granito.gerarSnapshot(),
      comprimento: '180',
      largura: '90',
    ),
    peca(
      id: 'perna',
      descricao: 'Perna',
      material: madeira.gerarSnapshot(),
      comprimento: '75',
      largura: '8',
      espessura: '8',
      quantidade: 4,
    ),
  ],
);

/// Exemplo B (prompt §9): 3 painéis, base R$ 150,00, uma peça de MDF
/// 120 × 60 a R$ 90,00/m².
final ItemOrcamento itemB = ItemOrcamento(
  id: 'item-b',
  descricao: 'Painel em MDF',
  quantidadeProdutos: 3,
  precoBase: Dinheiro.parse('150,00'),
  pecas: [
    peca(
      id: 'painel',
      descricao: 'Painel',
      material: mdf.gerarSnapshot(),
      comprimento: '120',
      largura: '60',
    ),
  ],
);

/// Exemplo C (prompt §9): A e B com adicionais e desconto, na edição.
final OrcamentoEmEdicao edicaoC = OrcamentoEmEdicao(
  chaveFinalizacao: 'chave-c',
  emitente: empresaTeste.gerarSnapshot(),
  cliente: clienteTeste.gerarSnapshot(),
  itens: [itemA, itemB],
  insumos: Dinheiro.parse('100,00'),
  impostos: Dinheiro.parse('200,00'),
  combustivel: Dinheiro.parse('50,00'),
  outros: Dinheiro.parse('30,00'),
  outrosDescricao: 'Frete',
  desconto: Dinheiro.parse('100,00'),
  validadeDias: 15,
  observacoes: 'Prazo combinado na visita.',
);
