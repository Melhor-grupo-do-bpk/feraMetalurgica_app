import 'package:fera_metalurgica_app/core/domain/dinheiro.dart';
import 'package:fera_metalurgica_app/core/domain/documento.dart';
import 'package:fera_metalurgica_app/core/domain/endereco.dart';
import 'package:fera_metalurgica_app/core/domain/medida_cm.dart';
import 'package:fera_metalurgica_app/features/empresa/empresa.dart';
import 'package:fera_metalurgica_app/features/materiais/materiais.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/cliente_snapshot.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/empresa_snapshot.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/item_orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/material_snapshot.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/orcamento_em_edicao.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/peca_orcamento.dart';

// Orçamentos de exemplo dos dados de debug (D-17): os exemplos A e B do
// prompt §9. São sessões de edição, gravadas pelo `FinalizarOrcamentoService`
// (que calcula os totais, cria os clientes e gera os códigos).

/// Cliente PF do exemplo C (A + B).
const ClienteSnapshot clienteExemploPf = ClienteSnapshot(
  nome: 'João da Silva',
  documento: Documento('52998224725'),
  celular: '(11) 99999-8888',
  endereco: Endereco(
    logradouro: 'Rua das Palmeiras',
    numero: '250',
    bairro: 'Jardim América',
    cidade: 'São Paulo',
    uf: 'SP',
    cep: '01455000',
  ),
);

/// Cliente PJ do exemplo B sozinho.
const ClienteSnapshot clienteExemploPj = ClienteSnapshot(
  nome: 'Construtora Horizonte Ltda',
  documento: Documento('11222333000181'),
  celular: '(11) 98888-7777',
  endereco: Endereco(
    logradouro: 'Av. Paulista',
    numero: '1500',
    complemento: 'Sala 12',
    bairro: 'Bela Vista',
    cidade: 'São Paulo',
    uf: 'SP',
  ),
);

PecaOrcamento _peca(
  String Function() gerarId, {
  required String descricao,
  required Material material,
  required String comprimento,
  required String largura,
  String? espessura,
  int quantidade = 1,
}) => PecaOrcamento(
  id: gerarId(),
  descricao: descricao,
  quantidadePorProduto: quantidade,
  material: material.gerarSnapshot(),
  comprimentoCm: MedidaCm.parse(comprimento),
  larguraCm: MedidaCm.parse(largura),
  espessuraCm: espessura == null ? null : MedidaCm.parse(espessura),
);

/// Exemplo A: 2 mesas de granito e madeira, base R$ 800,00 (R$ 2.706,40).
ItemOrcamento itemMesaExemplo(String Function() gerarId) => ItemOrcamento(
  id: gerarId(),
  descricao: 'Mesa de jantar sob medida',
  quantidadeProdutos: 2,
  precoBase: Dinheiro.parse('800,00'),
  pecas: [
    _peca(
      gerarId,
      descricao: 'Tampo',
      material: granitoExemplo,
      comprimento: '180',
      largura: '90',
    ),
    _peca(
      gerarId,
      descricao: 'Perna',
      material: madeiraExemplo,
      comprimento: '75',
      largura: '8',
      espessura: '8',
      quantidade: 4,
    ),
  ],
);

/// Exemplo B: 3 painéis de MDF, base R$ 150,00 (R$ 644,40).
ItemOrcamento itemPainelExemplo(String Function() gerarId) => ItemOrcamento(
  id: gerarId(),
  descricao: 'Painel em MDF',
  quantidadeProdutos: 3,
  precoBase: Dinheiro.parse('150,00'),
  pecas: [
    _peca(
      gerarId,
      descricao: 'Painel',
      material: mdfExemplo,
      comprimento: '120',
      largura: '60',
    ),
  ],
);

/// Exemplo C (A + B, adicionais e desconto): total geral R$ 3.630,80.
OrcamentoEmEdicao edicaoExemploC(String Function() gerarId) =>
    OrcamentoEmEdicao(
      chaveFinalizacao: gerarId(),
      emitente: empresaExemplo.gerarSnapshot(),
      cliente: clienteExemploPf,
      itens: [itemMesaExemplo(gerarId), itemPainelExemplo(gerarId)],
      insumos: Dinheiro.parse('100,00'),
      impostos: Dinheiro.parse('200,00'),
      combustivel: Dinheiro.parse('50,00'),
      outros: Dinheiro.parse('30,00'),
      outrosDescricao: 'Frete',
      desconto: Dinheiro.parse('100,00'),
      validadeDias: 15,
      observacoes: 'Prazo de entrega a combinar na aprovação.',
    );

/// Exemplo B sozinho, sem adicionais: total geral R$ 644,40.
OrcamentoEmEdicao edicaoExemploB(String Function() gerarId) =>
    OrcamentoEmEdicao(
      chaveFinalizacao: gerarId(),
      emitente: empresaExemplo.gerarSnapshot(),
      cliente: clienteExemploPj,
      itens: [itemPainelExemplo(gerarId)],
    );
