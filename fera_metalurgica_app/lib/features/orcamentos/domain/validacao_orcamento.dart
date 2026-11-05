// Validação da composição e do orçamento (prompt §6). Cada função devolve a
// lista de `ErroValidacao` encontrados, vazia se tudo estiver certo, e nunca
// altera os dados. Os caminhos seguem o formato
// `itens[0].pecas[1].espessuraCm`.
//
// Total geral zero NÃO é erro: é permitido e sinalizado por
// `ResultadoOrcamento.totalGeralZero`.

import 'package:fera_metalurgica_app/core/domain/dinheiro.dart';
import 'package:fera_metalurgica_app/core/domain/erro_validacao.dart';
import 'package:fera_metalurgica_app/core/domain/medida_cm.dart';
import 'package:fera_metalurgica_app/core/domain/unidade_cobranca.dart';
import 'package:fera_metalurgica_app/core/domain/validacao_comum.dart';
import 'package:fera_metalurgica_app/features/clientes/clientes.dart';
import 'package:fera_metalurgica_app/features/empresa/empresa.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/calculadora_orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/item_orcamento.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/orcamento_em_edicao.dart';
import 'package:fera_metalurgica_app/features/orcamentos/domain/peca_orcamento.dart';

/// Peça: descrição, material com nome e preço aplicado maior que zero,
/// quantidade por produto ≥ 1, comprimento e largura positivos e
/// espessura positiva (obrigatória em m³; em m², se informada).
List<ErroValidacao> validarPeca(PecaOrcamento peca, {String caminho = ''}) {
  String c(String campo) => juntarCaminho(caminho, campo);
  final espessura = peca.espessuraCm;
  return [
    ...validarTextoObrigatorio(peca.descricao, c('descricao')),
    ...validarTextoObrigatorio(peca.material.nome, c('material.nome')),
    if (!peca.material.precoAplicado.ehPositivo)
      ErroValidacao(
        caminhoCampo: c('material.precoAplicado'),
        codigo: CodigoErroValidacao.naoPositivo,
        mensagem: 'O preço aplicado deve ser maior que zero',
      ),
    if (peca.quantidadePorProduto < 1)
      ErroValidacao(
        caminhoCampo: c('quantidadePorProduto'),
        codigo: CodigoErroValidacao.minimoUm,
        mensagem: 'A quantidade por produto deve ser pelo menos 1',
      ),
    ..._medidaPositiva(peca.comprimentoCm, c('comprimentoCm'), 'comprimento'),
    ..._medidaPositiva(peca.larguraCm, c('larguraCm'), 'largura'),
    if (espessura == null && peca.material.unidade == UnidadeCobranca.m3)
      ErroValidacao(
        caminhoCampo: c('espessuraCm'),
        codigo: CodigoErroValidacao.obrigatorio,
        mensagem: 'Informe a espessura: o material é cobrado por m³',
      ),
    if (espessura != null)
      ..._medidaPositiva(espessura, c('espessuraCm'), 'espessura'),
  ];
}

/// Produto: descrição, quantidade ≥ 1, preço base não negativo e pelo menos
/// uma peça válida.
List<ErroValidacao> validarItem(ItemOrcamento item, {String caminho = ''}) {
  String c(String campo) => juntarCaminho(caminho, campo);
  return [
    ...validarTextoObrigatorio(item.descricao, c('descricao')),
    if (item.quantidadeProdutos < 1)
      ErroValidacao(
        caminhoCampo: c('quantidadeProdutos'),
        codigo: CodigoErroValidacao.minimoUm,
        mensagem: 'A quantidade de produtos deve ser pelo menos 1',
      ),
    ..._naoNegativo(item.precoBase, c('precoBase'), 'O preço base'),
    if (item.pecas.isEmpty)
      ErroValidacao(
        caminhoCampo: c('pecas'),
        codigo: CodigoErroValidacao.vazio,
        mensagem: 'Adicione pelo menos uma peça ao produto',
      ),
    for (final (i, peca) in item.pecas.indexed)
      ...validarPeca(peca, caminho: c('pecas[$i]')),
  ];
}

/// Orçamento em edição, antes de salvar: cliente e emitente válidos, pelo
/// menos um produto válido, adicionais não negativos, descrição de "outros"
/// quando maior que zero, validade positiva quando informada e desconto no
/// máximo igual ao subtotal.
///
/// O desconto só é comparado ao subtotal quando os itens e os adicionais
/// estão válidos, porque antes disso o subtotal não é confiável.
List<ErroValidacao> validarOrcamento(OrcamentoEmEdicao edicao) {
  final cliente = edicao.cliente;
  final emitente = edicao.emitente;
  final validadeDias = edicao.validadeDias;

  final errosItens = [
    if (edicao.itens.isEmpty)
      const ErroValidacao(
        caminhoCampo: 'itens',
        codigo: CodigoErroValidacao.vazio,
        mensagem: 'Adicione pelo menos um produto',
      ),
    for (final (i, item) in edicao.itens.indexed)
      ...validarItem(item, caminho: 'itens[$i]'),
  ];
  final errosAdicionais = [
    ..._naoNegativo(edicao.insumos, 'insumos', 'Insumos'),
    ..._naoNegativo(edicao.impostos, 'impostos', 'Impostos'),
    ..._naoNegativo(edicao.combustivel, 'combustivel', 'Combustível'),
    ..._naoNegativo(edicao.outros, 'outros', 'Outros'),
    ..._naoNegativo(edicao.desconto, 'desconto', 'O desconto'),
  ];

  return [
    if (cliente == null)
      const ErroValidacao(
        caminhoCampo: 'cliente',
        codigo: CodigoErroValidacao.obrigatorio,
        mensagem: 'Informe o cliente',
      )
    else
      ...validarDadosCliente(
        nome: cliente.nome,
        documento: cliente.documento,
        celular: cliente.celular,
        endereco: cliente.endereco,
        caminho: 'cliente',
      ),
    ...validarDadosEmpresa(
      nomeRazaoSocial: emitente.nomeRazaoSocial,
      documento: emitente.documento,
      telefone: emitente.telefone,
      endereco: emitente.endereco,
      email: emitente.email,
      caminho: 'emitente',
    ),
    ...errosItens,
    ...errosAdicionais,
    if (edicao.outros.ehPositivo)
      ...validarTextoObrigatorio(edicao.outrosDescricao, 'outrosDescricao'),
    if (validadeDias != null && validadeDias < 1)
      const ErroValidacao(
        caminhoCampo: 'validadeDias',
        codigo: CodigoErroValidacao.naoPositivo,
        mensagem: 'A validade deve ser de pelo menos 1 dia',
      ),
    if (errosItens.isEmpty &&
        errosAdicionais.isEmpty &&
        edicao.desconto > _subtotal(edicao))
      const ErroValidacao(
        caminhoCampo: 'desconto',
        codigo: CodigoErroValidacao.excedeSubtotal,
        mensagem: 'O desconto não pode ser maior que o subtotal',
      ),
  ];
}

Dinheiro _subtotal(OrcamentoEmEdicao edicao) => const CalculadoraOrcamento()
    .calcularOrcamento(
      itens: edicao.itens,
      insumos: edicao.insumos,
      impostos: edicao.impostos,
      combustivel: edicao.combustivel,
      outros: edicao.outros,
    )
    .subtotal;

List<ErroValidacao> _medidaPositiva(
  MedidaCm medida,
  String caminho,
  String nome,
) => [
  if (!medida.ehPositiva)
    ErroValidacao(
      caminhoCampo: caminho,
      codigo: CodigoErroValidacao.naoPositivo,
      mensagem: 'A $nome deve ser maior que zero',
    ),
];

List<ErroValidacao> _naoNegativo(
  Dinheiro valor,
  String caminho,
  String rotulo,
) => [
  if (valor.ehNegativo)
    ErroValidacao(
      caminhoCampo: caminho,
      codigo: CodigoErroValidacao.negativo,
      mensagem: '$rotulo não pode ser negativo',
    ),
];
