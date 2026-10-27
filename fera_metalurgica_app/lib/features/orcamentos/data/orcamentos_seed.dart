import 'package:fera_metalurgica_app/features/orcamentos/domain/cliente.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/custos_operacionais.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/item_orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/medidas.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/status_orcamento.dart';

/// Orçamentos de exemplo, com os nomes e valores das telas do Figma.
///
/// #00482 reproduz exatamente o fluxo do wizard (custos R$ 5.200,00 →
/// valor final R$ 8.450,00; item, medidas, material e prazo das etapas 2 e
/// 4). #00481 aparece só na lista do Figma com valor final R$ 12.300,00; a
/// divisão dos custos e o projeto dele são fictícios. #00480 (rascunho,
/// R$ 4.200,00) também vem da lista do Figma; #00479 (enviado, Construtora
/// Apex, R$ 15.200,00) vem do dashboard; #00478 (recusado) é fictício, para
/// que todo status tenha exemplo. Números de telefone e documentos são os
/// placeholders do Figma ou fictícios.
final List<Orcamento> orcamentosSeed = [
  Orcamento(
    id: '00482',
    cliente: const Cliente(
      id: 'cliente-joao-da-silva',
      nome: 'João da Silva',
      numero: '(99) 99999-9999',
      cpfCnpj: '123.456.789-09',
    ),
    projeto: 'Portão metálico',
    itens: const [
      ItemOrcamento(
        id: 'item-00482-1',
        tipoServico: 'Portão metálico basculante',
        medidas: Medidas(altura: 2.5, largura: 2.2),
        materialPrincipal: 'Aço Carbono',
        especificacoes: 'Estrutura tubular 50×50mm, chapa 18',
        produtoId: 'produto-portao-basculante',
      ),
    ],
    custosOperacionais: const CustosOperacionais(
      materiaPrima: 2450,
      maoDeObra: 1800,
      insumos: 350,
      combustivel: 180,
      impostos: 420,
    ),
    status: StatusOrcamento.emAnalise,
    criadoEm: DateTime(2026, 8, 17),
  ),
  Orcamento(
    id: '00481',
    cliente: const Cliente(
      id: 'cliente-metalurgica-abc',
      nome: 'Metalúrgica ABC Ltda',
      numero: '(99) 99999-9999',
      cpfCnpj: '12.345.678/0001-95',
    ),
    projeto: 'Estrutura treliçada',
    itens: const [
      ItemOrcamento(
        id: 'item-00481-1',
        tipoServico: 'Estrutura Treliçada',
        medidas: Medidas(largura: 8, comprimento: 12),
        materialPrincipal: 'Aço Carbono',
        especificacoes: 'Cobertura de galpão, pintura anticorrosiva',
        produtoId: 'produto-estrutura-trelicada',
      ),
    ],
    custosOperacionais: const CustosOperacionais(
      materiaPrima: 3800,
      maoDeObra: 2500,
      insumos: 600,
      combustivel: 219.23,
      impostos: 450,
    ),
    status: StatusOrcamento.aprovado,
    criadoEm: DateTime(2026, 8, 15),
  ),
  Orcamento(
    id: '00480',
    cliente: const Cliente(
      id: 'cliente-construtora-nova-era',
      nome: 'Construtora Nova Era',
      numero: '(99) 99999-9999',
      cpfCnpj: '11.222.333/0001-81',
    ),
    projeto: 'Grade de proteção',
    itens: const [
      ItemOrcamento(
        id: 'item-00480-1',
        tipoServico: 'Grade de Proteção Pesada',
        medidas: Medidas(altura: 2, largura: 1.5),
        quantidade: 4,
        produtoId: 'produto-grade-protecao-pesada',
      ),
    ],
    custosOperacionais: const CustosOperacionais(
      materiaPrima: 1500,
      maoDeObra: 800,
      insumos: 150,
      combustivel: 84.615,
      impostos: 50,
    ),
    status: StatusOrcamento.rascunho,
    criadoEm: DateTime(2026, 8, 12),
  ),
  Orcamento(
    id: '00479',
    cliente: const Cliente(
      id: 'cliente-construtora-apex',
      nome: 'Construtora Apex',
      numero: '(11) 98888-7777',
      cpfCnpj: '11.444.777/0001-61',
      email: 'contato@apex.com.br',
    ),
    projeto: 'Portões do condomínio',
    itens: const [
      ItemOrcamento(
        id: 'item-00479-1',
        tipoServico: 'Portão Basculante',
        medidas: Medidas(altura: 2.5, largura: 3),
        materialPrincipal: 'Aço Galvanizado',
        quantidade: 2,
        produtoId: 'produto-portao-basculante',
      ),
    ],
    custosOperacionais: const CustosOperacionais(
      materiaPrima: 5000,
      maoDeObra: 3000,
      insumos: 800,
      combustivel: 353.846,
      impostos: 200,
    ),
    status: StatusOrcamento.enviado,
    criadoEm: DateTime(2026, 8, 10),
  ),
  Orcamento(
    id: '00478',
    cliente: const Cliente(
      id: 'cliente-maria-souza',
      nome: 'Maria Souza',
      numero: '(99) 98765-4321',
      cpfCnpj: '529.982.247-25',
    ),
    projeto: 'Portão residencial',
    itens: const [
      ItemOrcamento(
        id: 'item-00478-1',
        tipoServico: 'Portão de correr',
        medidas: Medidas(altura: 1.8, largura: 3.5),
        materialPrincipal: 'Alumínio',
      ),
    ],
    custosOperacionais: const CustosOperacionais(
      materiaPrima: 1200,
      maoDeObra: 600,
      insumos: 100,
      combustivel: 50,
      impostos: 50,
    ),
    status: StatusOrcamento.recusado,
    criadoEm: DateTime(2026, 8, 5),
  ),
];
